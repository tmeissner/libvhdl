--  Copyright (c) 2014 - 2022 by Torsten Meissner
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      https://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.



library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;



entity WishBoneSlaveE is
  generic (
    Formal       : boolean := false;
    Simulation   : boolean := false;
    AddressWidth : natural := 32;
    DataWidth    : natural := 32
  );
  port (
    --+ wishbone system if
    WbRst_i       : in  std_logic;
    WbClk_i       : in  std_logic;
    --+ wishbone inputs
    WbCyc_i       : in  std_logic;
    WbStb_i       : in  std_logic;
    WbWe_i        : in  std_logic;
    WbAdr_i       : in  std_logic_vector(AddressWidth-1 downto 0);
    WbDat_i       : in  std_logic_vector(DataWidth-1 downto 0);
    --+ wishbone outputs
    WbDat_o       : out std_logic_vector(DataWidth-1 downto 0);
    WbAck_o       : out std_logic;
    WbErr_o       : out std_logic;
    --+ local register if
    LocalWen_o    : out std_logic;
    LocalRen_o    : out std_logic;
    LocalAdress_o : out std_logic_vector(AddressWidth-1 downto 0);
    LocalData_o   : out std_logic_vector(DataWidth-1 downto 0);
    LocalData_i   : in  std_logic_vector(DataWidth-1 downto 0)
  );
end entity WishBoneSlaveE;



architecture rtl of WishBoneSlaveE is


  type t_wb_slave_fsm is (IDLE, ADDRESS, DATA);
  signal s_wb_slave_fsm : t_wb_slave_fsm;

  signal s_wb_active : boolean;


begin


  WbSlaveControlP : process (WbClk_i) is
  begin
    if (rising_edge(WbClk_i)) then
      if (WbRst_i = '1') then
        s_wb_slave_fsm <= IDLE;
      else
        WbReadC : case s_wb_slave_fsm is

          when IDLE =>
            s_wb_slave_fsm <= ADDRESS;

          when ADDRESS =>
            if (s_wb_active and WbWe_i = '0') then
              s_wb_slave_fsm <= DATA;
            end if;

          when DATA =>
              s_wb_slave_fsm <= ADDRESS;

          when others  =>
            s_wb_slave_fsm <= IDLE;

        end case;
      end if;
    end if;
  end process WbSlaveControlP;


  s_wb_active <= true when s_wb_slave_fsm /= IDLE and WbCyc_i = '1' and WbStb_i = '1' else false;

  --+ local register if outputs
  LocalWen_o     <= WbWe_i      when s_wb_slave_fsm  = ADDRESS and s_wb_active else '0';
  LocalRen_o     <= not(WbWe_i) when s_wb_slave_fsm  = ADDRESS and s_wb_active else '0';
  LocalAdress_o  <= WbAdr_i     when s_wb_slave_fsm /= IDLE    and s_wb_active else (others => '0');
  LocalData_o    <= WbDat_i     when s_wb_slave_fsm  = ADDRESS and s_wb_active and WbWe_i = '1' else (others => '0');

  --+ wishbone if outputs
  WbDat_o <= LocalData_i when s_wb_slave_fsm = DATA and WbWe_i = '0' else (others => '0');
  WbAck_o <= '1'         when (s_wb_slave_fsm = DATA and WbWe_i = '0') or (s_wb_slave_fsm = ADDRESS and s_wb_active and WbWe_i = '1') else '0';
  WbErr_o <= '1' when s_wb_slave_fsm = DATA and WbWe_i = '1' else '0';


  default clock is rising_edge(WbClk_i);

  FormalG : if Formal generate

    -- Glue logic
    signal s_wb_data    : std_logic_vector(DataWidth-1 downto 0);
    signal s_wb_address : std_logic_vector(AddressWidth-1 downto 0);

  begin

    SyncWbSignals : process is
    begin
      wait until rising_edge(WbClk_i);
      if (s_wb_slave_fsm = ADDRESS and WbCyc_i = '1' and WbStb_i = '1') then
        if (WbWe_i = '1') then
          s_wb_data <= WbDat_i;
        end if;
        s_wb_address <= WbAdr_i;
      end if;
    end process SyncWbSignals;

    restrict {WbRst_i = '1'; WbRst_i = '0'[+]}[*1];

    assume always WbCyc_i = WbStb_i;
    assume always WbWe_i  -> WbStb_i;
    assume always WbWe_i and WbAck_o -> next not WbWe_i;

    -- FSM state checks
    FSM_IDLE_TO_ADDRESS : assert always
      not WbRst_i and s_wb_slave_fsm = IDLE ->
      next s_wb_slave_fsm = ADDRESS abort WbRst_i;

    FSM_ADDRESS_TO_DATA : assert always
      not WbRst_i and s_wb_slave_fsm = ADDRESS and WbStb_i and WbCyc_i and not WbWe_i ->
      next s_wb_slave_fsm = DATA abort WbRst_i;

    FSM_ADDRESS_TO_ADDRESS : assert always
      not WbRst_i and s_wb_slave_fsm = ADDRESS and not (WbStb_i and WbCyc_i and not WbWe_i) ->
      next s_wb_slave_fsm = ADDRESS abort WbRst_i;

    FSM_DATA_TO_ADDRESS : assert always
      not WbRst_i and s_wb_slave_fsm = DATA ->
      next s_wb_slave_fsm = ADDRESS abort WbRst_i;

    -- Wishbone write cycle checks
    WB_WRITE_CYCLE_0 : assert always
      s_wb_slave_fsm = ADDRESS and WbStb_i and WbCyc_i and WbWe_i ->
      LocalWen_o and WbAck_o;

    WB_WRITE_CYCLE_1 : assert always
      LocalWen_o -> LocalAdress_o = WbAdr_i;

    WB_WRITE_CYCLE_2 : assert always
      LocalWen_o -> LocalData_o = WbDat_i;

    -- Wishbone read cycle checks
    WB_READ_CYCLE_0 : assert always
      s_wb_slave_fsm = ADDRESS and WbStb_i and WbCyc_i and not WbWe_i ->
      LocalRen_o and not WbAck_o;

    WB_READ_CYCLE_1 : assert always
      LocalRen_o -> LocalAdress_o = WbAdr_i;

    WB_READ_CYCLE_2 : assert always
      s_wb_slave_fsm = DATA and not WbWe_i ->
      WbAck_o and WbDat_o = LocalData_i;

    WB_READ_ERROR : assert always
      s_wb_slave_fsm = DATA and WbWe_i ->
      WbErr_o;

    WB_NEVER_ACK_AND_ERR : assert never
      WbAck_o and WbErr_o;

    WB_ERR : assert always
      WbErr_o ->
      (WbCyc_i and WbStb_i)
      report "PSL ERROR: WbErr invalid";

    LOCAL_WE : assert always
      LocalWen_o ->
      (WbCyc_i and WbStb_i and WbWe_i and not LocalRen_o) and
      (next not LocalWen_o)
      report "PSL ERROR: LocalWen invalid";

    LOCAL_RE : assert always
      LocalRen_o ->
      (WbCyc_i and WbStb_i and not WbWe_i and not LocalWen_o) and
      (next not LocalRen_o)
      report "PSL ERROR: LocalRen invalid";

    RESET : assert always
      WbRst_i -> next
      (to_integer(unsigned(WbDat_o)) = 0 and WbAck_o = '0' and WbErr_o = '0' and
       LocalWen_o = '0' and LocalRen_o = '0' and to_integer(unsigned(LocalAdress_o)) = 0 and to_integer(unsigned(LocalData_o)) = 0)
      report "PSL ERROR: Reset error";

  end generate FormalG;


  SimulationG : if Simulation generate

    LOCAL_WRITE : assert always
      ((WbCyc_i and WbStb_i and WbWe_i) ->
       (LocalWen_o = '1' and WbAck_o = '1' and LocalAdress_o = WbAdr_i and LocalData_o = WbDat_i)) abort WbRst_i
      report "PSL ERROR: Local write error";

    LOCAL_READ : assert always
      ({not(WbCyc_i) and not(WbStb_i); WbCyc_i and WbStb_i and not(WbWe_i)} |->
       {LocalRen_o = '1' and LocalAdress_o = WbAdr_i and WbAck_o = '0'; LocalRen_o = '0' and WbDat_o = LocalData_i and WbAck_o = '1'}) abort WbRst_i
      report "PSL ERROR: Local read error";

    WB_ACK : assert always
      WbAck_o ->
      (WbCyc_i and WbStb_i)
      report "PSL ERROR: WbAck invalid";

    WB_ERR : assert always
      WbErr_o ->
      (WbCyc_i and WbStb_i)
      report "PSL ERROR: WbErr invalid";

    LOCAL_WE : assert always
      LocalWen_o ->
      (WbCyc_i and WbStb_i and WbWe_i and not(LocalRen_o)) and
      (next not(LocalWen_o))
      report "PSL ERROR: LocalWen invalid";

    LOCAL_RE : assert always
      LocalRen_o ->
      (WbCyc_i and WbStb_i and not(WbWe_i) and not(LocalWen_o)) and
      (next not(LocalRen_o))
      report "PSL ERROR: LocalRen invalid";

    RESET : assert always
      WbRst_i ->
      (to_integer(unsigned(WbDat_o)) = 0 and WbAck_o = '0' and WbErr_o = '0' and
       LocalWen_o = '0' and LocalRen_o = '0' and to_integer(unsigned(LocalAdress_o)) = 0 and to_integer(unsigned(LocalData_o)) = 0)
      report "PSL ERROR: Reset error";

  end generate SimulationG;


end architecture rtl;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;



entity WishBoneSlaveE is
  generic (
    AddressWidth : natural := 8;
    DataWidth    : natural := 8
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
  WbAck_o <= '1'         when s_wb_slave_fsm = DATA or (s_wb_slave_fsm = ADDRESS and s_wb_active and WbWe_i = '1') else '0';
  WbErr_o <= '0';


  -- psl default clock is rising_edge(WbClk_i);
  --
  -- psl LOCAL_WRITE : assert always
  --   ((WbCyc_i and WbStb_i and WbWe_i) ->
  --    (LocalWen_o = '1' and WbAck_o = '1' and LocalAdress_o = WbAdr_i and LocalData_o = WbDat_i)) abort WbRst_i
  --   report "PSL ERROR: Local write error";
  --
  -- psl LOCAL_READ : assert always
  --   ({not(WbCyc_i) and not(WbStb_i); WbCyc_i and WbStb_i and not(WbWe_i)} |->
  --    {LocalRen_o = '1' and LocalAdress_o = WbAdr_i and WbAck_o = '0'; LocalRen_o = '0' and WbDat_o = LocalData_i and WbAck_o = '1'}) abort WbRst_i
  --   report "PSL ERROR: Local read error";
  --
  -- psl WB_ACK : assert always
  --   WbAck_o ->
  --   (WbCyc_i and WbStb_i)
  --   report "PSL ERROR: WbAck invalid";
  --
  --  psl WB_ERR : assert always
  --   WbErr_o ->
  --   (WbCyc_i and WbStb_i)
  --   report "PSL ERROR: WbErr invalid";
  --
  -- psl LOCAL_WE : assert always
  --   LocalWen_o ->
  --   (WbCyc_i and WbStb_i and WbWe_i and not(LocalRen_o)) and
  --   (next not(LocalWen_o))
  --   report "PSL ERROR: LocalWen invalid";
  --
  --  psl LOCAL_RE : assert always
  --   LocalRen_o ->
  --   (WbCyc_i and WbStb_i and not(WbWe_i) and not(LocalWen_o)) and
  --   (next not(LocalRen_o))
  --   report "PSL ERROR: LocalRen invalid";
  --
  -- psl RESET : assert always
  --   WbRst_i ->
  --   (to_integer(unsigned(WbDat_o)) = 0 and WbAck_o = '0' and WbErr_o = '0' and
  --    LocalWen_o = '0' and LocalRen_o = '0' and to_integer(unsigned(LocalAdress_o)) = 0 and to_integer(unsigned(LocalData_o)) = 0)
  --   report "PSL ERROR: Reset error";


end architecture rtl;

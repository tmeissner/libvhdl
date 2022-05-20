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


library osvvm;
  use osvvm.RandomPkg.all;

library libvhdl;
  use libvhdl.AssertP.all;
  use libvhdl.SimP.all;
  use libvhdl.UtilsP.all;



entity SimT is
end entity SimT;



architecture sim of SimT is


  --* testbench global clock period
  constant C_PERIOD : time := 5 ns;
  --* SPI data transfer data width
  constant C_DATA_WIDTH : natural := 8;

  signal s_tests_done : boolean_vector(0 to 1) := (others => false);

  signal s_clk  : std_logic := '0';

  signal s_sclk : std_logic;
  signal s_ste  : std_logic;
  signal s_mosi : std_logic;
  signal s_miso : std_logic;

  package SlvQueue is new libvhdl.QueueP
    generic map (
      QUEUE_TYPE => std_logic_vector(C_DATA_WIDTH-1 downto 0),
      MAX_LEN    => 32,
      to_string  => to_hstring
    );

  shared variable sv_mosi_queue : SlvQueue.t_list_queue;
  shared variable sv_miso_queue : SlvQueue.t_list_queue;


begin


  s_clk <= not(s_clk) after C_PERIOD when not(and_reduce(s_tests_done)) else '0';


  QueueInitP : process is
  begin
    sv_mosi_queue.init(false);
    sv_miso_queue.init(false);
    wait;
  end process QueueInitP;


  SimTestP : process is
    variable v_time : time;
  begin
    wait until s_clk = '1';
    v_time := now;
    wait_cycles(s_clk, 10);
    assert (now - v_time) = C_PERIOD * 20
      severity failure;
    s_tests_done(0) <= true;
    report "INFO: wait_cycles() procedure tests finished successfully";
    wait;
  end process SimTestP;


  -- Unit test of spi master procedure, checks all combinations
  -- of cpol & cpha against spi slave procedure
  SpiMasterP : process is
    variable v_send_data    : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
    variable v_receive_data : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
    variable v_queue_data   : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
    variable v_random       : RandomPType;
  begin
    v_random.InitSeed(v_random'instance_name);
    for direction in 0 to 1 loop
      for mode in 0 to 3 loop
        for i in 0 to 255 loop
          v_send_data := v_random.RandSlv(C_DATA_WIDTH);
          sv_mosi_queue.push(v_send_data);
          spi_master (data_in  => v_send_data,
                      data_out => v_receive_data,
                      sclk     => s_sclk,
                      ste      => s_ste,
                      mosi     => s_mosi,
                      miso     => s_miso,
                      dir      => direction,
                      cpol     => mode / 2,
                      cpha     => mode mod 2,
                      period   => 1 us
          );
          sv_miso_queue.pop(v_queue_data);
          assert_equal(v_receive_data, v_queue_data);
        end loop;
      end loop;
    end loop;
    wait;
  end process SpiMasterP;


  -- Unit test of spi slave procedure, checks all combinations
  -- of cpol & cpha against spi master procedure
  SpiSlaveP : process is
    variable v_send_data    : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
    variable v_receive_data : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
    variable v_queue_data   : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
    variable v_random       : RandomPType;
  begin
    v_random.InitSeed(v_random'instance_name);
    for direction in 0 to 1 loop
      for mode in 0 to 3 loop
        for i in 0 to 255 loop
          v_send_data := v_random.RandSlv(C_DATA_WIDTH);
          sv_miso_queue.push(v_send_data);
          spi_slave (data_in  => v_send_data,
                     data_out => v_receive_data,
                     sclk     => s_sclk,
                     ste      => s_ste,
                     mosi     => s_mosi,
                     miso     => s_miso,
                     dir      => direction,
                     cpol     => mode / 2,
                     cpha     => mode mod 2
          );
          sv_mosi_queue.pop(v_queue_data);
          assert_equal(v_receive_data, v_queue_data);
        end loop;
      end loop;
    end loop;
    report "INFO: All tests of valid spi_master() & spi_slave() combinations finished successfully";
    s_tests_done(1) <= true;
    wait;
  end process SpiSlaveP;


end architecture sim;

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
  use osvvm.CoveragePkg.all;

use std.env.all;


entity UartT is
end entity UartT;



architecture sim of UartT is


  constant c_data_length : positive range 5 to 9 := 8;
  constant c_parity      : boolean := true;
  constant c_clk_div     : natural := 10;

  signal s_reset_n   : std_logic := '0';
  signal s_clk       : std_logic := '1';
  signal s_tx_data   : std_logic_vector(c_data_length-1 downto 0);
  signal s_tx_valid  : std_logic;
  signal s_tx_accept : std_logic;

  signal s_rx_data   : std_logic_vector(c_data_length-1 downto 0);
  signal s_rx_error  : std_logic;
  signal s_rx_valid  : std_logic;
  signal s_rx_accept : std_logic;

  signal s_tx_uart   : std_logic := '1';
  signal s_rx_uart   : std_logic := '1';

  type t_error is (NONE, DATA, STOP);
  signal s_error_inject   : t_error := NONE;
  signal s_error_injected : t_error := NONE;

  shared variable sv_uart_err_coverage : CovPType;

  procedure injectError (signal inject : out t_error) is
    variable v_injected : boolean;
    variable v_random   : RandomPType;
  begin
    v_random.InitSeed(v_random'instance_name & to_string(now));
    loop
      -- Wait for new UART transmission
      v_injected := false;
      wait until s_tx_valid = '1' and s_tx_accept = '1';
      wait until falling_edge(s_tx_uart);
      -- Skip start bit
      for i in 0 to c_clk_div-1 loop
        wait until rising_edge(s_clk);
      end loop;
      -- Possibly distort one of the data bits
      -- and update coverage object
      for i in 0 to c_data_length loop
        if (not v_injected and v_random.DistValInt(((0, 9), (1, 1))) = 1) then
          v_injected := true;
          sv_uart_err_coverage.ICover(i);
          if (i = c_data_length) then
            inject <= STOP;
            report "Injected transmit error on stop bit";
          else
            inject <= DATA;
            report "Injected transmit error on data bit #" & to_string(i);
          end if;
        end if;
        for y in 0 to c_clk_div-1 loop
          wait until rising_edge(s_clk);
        end loop;
        inject <= NONE;
      end loop;
    end loop;
    wait;
  end procedure injectError;


begin


  Dut_UartTx : entity work.UartTx
    generic map (
      DATA_LENGTH => c_data_length,
      PARITY      => c_parity,
      CLK_DIV     => c_clk_div
    )
    port map (
      reset_n_i => s_reset_n,
      clk_i     => s_clk,
      data_i    => s_tx_data,
      valid_i   => s_tx_valid,
      accept_o  => s_tx_accept,
      tx_o      => s_tx_uart
    );


  -- Error injection based on random
  sv_uart_err_coverage.AddBins("DATA_ERROR", GenBin(0, c_data_length-1));
  sv_uart_err_coverage.AddBins("STOP_ERROR", GenBin(c_data_length));
  injectError(s_error_inject);
  s_rx_uart <= s_tx_uart when s_error_inject = NONE else not(s_tx_uart);


  Dut_UartRx : entity work.UartRx
    generic map (
      DATA_LENGTH => c_data_length,
      PARITY      => c_parity,
      CLK_DIV     => c_clk_div
    )
    port map (
      reset_n_i => s_reset_n,
      clk_i     => s_clk,
      data_o    => s_rx_data,
      error_o   => s_rx_error,
      valid_o   => s_rx_valid,
      accept_i  => s_rx_accept,
      rx_i      => s_rx_uart
    );


  s_clk     <= not s_clk after 5 ns;
  s_reset_n <= '1' after 20 ns;


  -- Store if an error was injected in the current frame
  s_error_injected <= s_error_inject when rising_edge(s_clk) and s_error_inject /= NONE else
                      NONE when s_tx_valid = '1';


  TestP : process is
    variable v_data   : std_logic_vector(c_data_length-1 downto 0);
    variable v_random : RandomPType;
  begin
    v_random.InitSeed(v_random'instance_name);
    s_tx_valid  <= '0';
    s_rx_accept <= '0';
    s_tx_data   <= (others => '0');
    wait until s_reset_n = '1';
    for i in 0 to 2**c_data_length-1 loop
      wait until rising_edge(s_clk);
      s_tx_valid  <= '1';
      s_rx_accept <= '1';
      v_data      := v_random.RandSlv(8);
      s_tx_data   <= v_data;
      report "Testcase #" & to_string(i) & ": Transmit 0x" & to_hstring(v_data);
      wait until rising_edge(s_clk) and s_tx_accept = '1';
      s_tx_valid <= '0';
      wait until rising_edge(s_clk) and s_rx_valid = '1';
      if s_error_injected /= NONE then
        if s_error_injected = DATA then
          assert s_rx_data /= v_data
            report "Received data 0x" & to_hstring(s_rx_data) & ", expected 0x" & to_hstring(v_data)
            severity failure;
        end if;
        assert s_rx_error = '1'
          report "Received error 0b" & to_string(s_rx_error) & ", expected 0b1"
          severity failure;
      else
        assert s_rx_data = v_data
          report "Received data 0x" & to_hstring(s_rx_data) & ", expected 0x" & to_hstring(v_data)
          severity failure;
        assert s_rx_error = '0'
          report "Received error 0b" & to_string(s_rx_error) & ", expected 0b0"
          severity failure;
      end if;
    end loop;
    wait for 10 us;
    sv_uart_err_coverage.SetMessage("UART bit error coverage");
    sv_uart_err_coverage.WriteBin;
    finish(0);
  end process TestP;


end architecture sim;

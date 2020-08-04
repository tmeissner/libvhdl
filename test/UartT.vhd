-- ======================================================================
-- UART testbench
-- Copyright (C) 2020 Torsten Meissner
-------------------------------------------------------------------------
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 3 of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program; if not, write to the Free Software Foundation,
-- Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
-- ======================================================================


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


  component UartTx is
    generic (
      DATA_LENGTH : positive range 5 to 9 := 8;
      PARITY      : boolean := false;
      CLK_DIV     : natural := 10
    );
    port (
      reset_n_i   : in  std_logic;                                 -- async reset
      clk_i       : in  std_logic;                                 -- clock
      data_i      : in  std_logic_vector(DATA_LENGTH-1 downto 0);  -- data input
      valid_i     : in  std_logic;                                 -- input data valid
      accept_o    : out std_logic;                                 -- inpit data accepted
      tx_o        : out std_logic                                  -- uart tx data output
    );
  end component UartTx;

  component UartRx is
    generic (
      DATA_LENGTH : positive range 5 to 9 := 8;
      PARITY      : boolean := true;
      CLK_DIV     : natural := 10
    );
    port (
      reset_n_i   : in  std_logic;                                 -- async reset
      clk_i       : in  std_logic;                                 -- clock
      data_o      : out std_logic_vector(DATA_LENGTH-1 downto 0);  -- data output
      error_o     : out std_logic;                                 -- rx error
      valid_o     : out std_logic;                                 -- output data valid
      accept_i    : in  std_logic;                                 -- output data accepted
      rx_i        : in  std_logic                                  -- uart rx input
    );
  end component UartRx;

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

  signal s_error_inject   : boolean := false;
  signal s_error_injected : boolean := false;

  shared variable sv_uart_err_coverage : CovPType;

  procedure injectError (signal inject : out boolean) is
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
      for i in 0 to c_data_length-1 loop
        if (not v_injected and v_random.DistValInt(((0, 9), (1, 1))) = 1) then
          v_injected := true;
          inject     <= true;
          sv_uart_err_coverage.ICover(i);
          report "Injected transmit error on bit #" & to_string(i);
        end if;
        for y in 0 to c_clk_div-1 loop
          wait until rising_edge(s_clk);
        end loop;
        inject <= false;
      end loop;
    end loop;
    wait;
  end procedure injectError;


begin


  Dut_UartTx : UartTx
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
  sv_uart_err_coverage.AddBins(GenBin(0, c_data_length-1));
  injectError(s_error_inject);
  s_rx_uart <= s_tx_uart when not s_error_inject else not(s_tx_uart);


  Dut_UartRx : UartRx
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
  s_error_injected <= true  when rising_edge(s_clk) and s_error_inject else
                      false when s_tx_valid = '1';


  TestP : process is
    variable v_data   : std_logic_vector(c_data_length-1 downto 0);
    variable v_error  : boolean := false;
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
      if s_error_injected then
        assert s_rx_data /= v_data
          report "Received data 0x" & to_hstring(s_rx_data) & ", expected 0x" & to_hstring(v_data)
          severity failure;
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

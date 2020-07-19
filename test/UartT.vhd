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

  constant c_data_length : positive range 5 to 8 := 8;

  signal s_reset_n   : std_logic := '0';
  signal s_clk       : std_logic := '1';
  signal s_tx_data   : std_logic_vector(c_data_length-1 downto 0);
  signal s_tx_valid  : std_logic;
  signal s_tx_accept : std_logic;

  signal s_rx_data   : std_logic_vector(c_data_length-1 downto 0);
  signal s_rx_error  : std_logic;
  signal s_rx_valid  : std_logic;
  signal s_rx_accept : std_logic;

  signal s_uart      : std_logic;


begin


  Dut_UartTx : UartTx
    generic map (
      DATA_LENGTH => c_data_length,
      PARITY      => true,
      CLK_DIV     => 10
    )
    port map (
      reset_n_i => s_reset_n,
      clk_i     => s_clk,
      data_i    => s_tx_data,
      valid_i   => s_tx_valid,
      accept_o  => s_tx_accept,
      tx_o      => s_uart
    );


  Dut_UartRx : UartRx
    generic map (
      DATA_LENGTH => c_data_length,
      PARITY      => true,
      CLK_DIV     => 10
    )
    port map (
      reset_n_i => s_reset_n,
      clk_i     => s_clk,
      data_o    => s_rx_data,
      error_o   => s_rx_error,
      valid_o   => s_rx_valid,
      accept_i  => s_rx_accept,
      rx_i      => s_uart
    );


  s_clk     <= not s_clk after 5 ns;
  s_reset_n <= '1' after 20 ns;


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
      wait until rising_edge(s_clk) and s_tx_accept = '1';
      s_tx_valid <= '0';
      wait until rising_edge(s_clk) and s_rx_valid = '1';
      assert s_rx_data = v_data
        report "Received data 0x" & to_hstring(s_rx_data) & ", expected 0x" & to_hstring(v_data)
        severity failure;
      assert s_rx_error = '0'
        report "Received error 0b" & to_string(s_rx_error) & ", expected 0b0"
        severity failure;
    end loop;
    wait for 10 us;
    stop(0);
  end process TestP;


end architecture sim;

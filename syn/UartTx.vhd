-- ======================================================================
-- UART transmitter
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

library libvhdl;
use libvhdl.UtilsP.all;



entity UartTx is
  generic (
    DATA_LENGTH : positive range 5 to 9 := 8;
    PARITY      : boolean := true;
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
end entity UartTx;



architecture rtl of UartTx is


  function to_integer (data : in boolean) return integer is
  begin
    if data then
      return 1;
    else
      return 0;
    end if;
  end function to_integer;


  type t_uart_state is (IDLE, SEND);
  signal s_uart_state : t_uart_state;

  signal s_data   : std_logic_vector(DATA_LENGTH+1+to_integer(PARITY) downto 0);
  signal s_clk_en : boolean;


begin


  ClkDivP : process (clk_i, reset_n_i) is
    variable v_clk_cnt : natural range 0 to CLK_DIV-1;
  begin
    if (reset_n_i = '0') then
      s_clk_en  <= false;
      v_clk_cnt := CLK_DIV-1;
    elsif (rising_edge(clk_i)) then
      if (s_uart_state = IDLE) then
        v_clk_cnt := CLK_DIV-2;
        s_clk_en  <= false;
      elsif (s_uart_state = SEND) then
        if (v_clk_cnt = 0) then
          v_clk_cnt := CLK_DIV-1;
          s_clk_en  <= true;
        else
          v_clk_cnt := v_clk_cnt - 1;
          s_clk_en  <= false;
        end if;
      end if;
    end if;
  end process ClkDivP;


  TxP : process (clk_i, reset_n_i) is
    variable v_bit_cnt : natural range 0 to s_data'length-1;
  begin
    if (reset_n_i = '0') then
      s_uart_state <= IDLE;
      s_data       <= (0 => '1', others => '0');
      accept_o     <= '0';
      v_bit_cnt    := 0;
    elsif (rising_edge(clk_i)) then
      FsmL : case s_uart_state is
        when IDLE =>
          accept_o  <= '1';
          v_bit_cnt := s_data'length-1;
          if (valid_i = '1' and accept_o = '1') then
            accept_o     <= '0';
            if (PARITY) then
              s_data <= '1' & odd_parity(data_i) & data_i & '0';
            else
              s_data <= '1' & data_i & '0';
            end if;
            s_uart_state <= SEND;
          end if;
        when SEND =>
          if (s_clk_en) then
            s_data <= '1' & s_data(s_data'length-1 downto 1);
            if (v_bit_cnt = 0) then
              accept_o     <= '1';
              s_uart_state <= IDLE;
            else
              v_bit_cnt := v_bit_cnt - 1;
            end if;
          end if;
      end case;
    end if;
  end process TxP;


  tx_o <= s_data(0);


end architecture rtl;

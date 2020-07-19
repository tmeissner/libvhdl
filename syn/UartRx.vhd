-- ======================================================================
-- UART Receiver
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



entity UartRx is
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
end entity UartRx;



architecture rtl of UartRx is


  function odd_parity (data : in std_logic_vector(DATA_LENGTH-1 downto 0)) return std_logic is
    variable v_data : std_logic := '0';
  begin
    for i in data'range loop
      v_data := v_data xor data(i);
    end loop;
    return not v_data;
  end function odd_parity;

  function to_integer (data : in boolean) return integer is
  begin
    if data then
      return 1;
    else
      return 0;
    end if;
  end function to_integer;


  type t_uart_state is (IDLE, RECEIVE, VALID);
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
      s_clk_en <= false;
      if (s_uart_state = IDLE) then
        v_clk_cnt := CLK_DIV-2;
      elsif (s_uart_state = RECEIVE) then
        if (v_clk_cnt = 0) then
          v_clk_cnt := CLK_DIV-1;
        else
          v_clk_cnt := v_clk_cnt - 1;
        end if;
        if (v_clk_cnt = CLK_DIV/2-1) then
          s_clk_en <= true;
        end if;
      end if;
    end if;
  end process ClkDivP;


  RxP : process (clk_i, reset_n_i) is
    variable v_bit_cnt : natural range 0 to s_data'length-1;
  begin
    if (reset_n_i = '0') then
      s_uart_state <= IDLE;
      s_data       <= (others => '0');
      valid_o      <= '0';
      v_bit_cnt    := 0;
    elsif (rising_edge(clk_i)) then
      FsmL : case s_uart_state is
        when IDLE =>
          valid_o   <= '0';
          v_bit_cnt := s_data'length-1;
          if (rx_i = '0') then
            s_uart_state <= RECEIVE;
          end if;
        when RECEIVE =>
          if (s_clk_en) then
            s_data <= rx_i & s_data(s_data'length-1 downto 1);
            if (v_bit_cnt = 0) then
              valid_o      <= '1';
              s_uart_state <= VALID;
            else
              v_bit_cnt := v_bit_cnt - 1;
            end if;
          end if;
        when VALID =>
          valid_o <= '1';
          if (valid_o = '1' and accept_i = '1') then
            valid_o      <= '0';
            s_uart_state <= IDLE;
          end if;
      end case;
    end if;
  end process RxP;


  ParityG : if PARITY generate
    data_o  <= s_data(s_data'length-3 downto 1);
    error_o <= '1' when odd_parity(s_data(s_data'length-3 downto 1)) /= s_data(s_data'length-2) or
                        s_data(s_data'length-1) = '0' else
               '0';
  else generate
    data_o  <= s_data(s_data'length-2 downto 1);
    error_o <= '1' when s_data(s_data'length-1) = '0' else '0';
  end generate ParityG;


end architecture rtl;

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

--+ including vhdl 2008 libraries
--+ These lines can be commented out when using
--+ a simulator with built-in VHDL 2008 support
--library ieee_proposed;
--  use ieee_proposed.standard_additions.all;
--  use ieee_proposed.std_logic_1164_additions.all;

library libvhdl;
  use libvhdl.AssertP.all;




package SimP is


  procedure wait_cycles (signal clk : in std_logic; n : in natural);

  procedure spi_master (    data_in : in    std_logic_vector;  data_out : out std_logic_vector;
                        signal sclk : inout std_logic;       signal ste : out std_logic;
                        signal mosi : out   std_logic;      signal miso : in  std_logic;
                                dir : in    natural range 0 to 1;  cpol : in  natural range 0 to 1;
                                cpha : in  natural range 0 to 1; period : in  time);

  procedure spi_slave (    data_in : in std_logic_vector; data_out : out std_logic_vector;
                       signal sclk : in std_logic;      signal ste : in  std_logic;
                       signal mosi : in std_logic;     signal miso : out std_logic;
                               dir : in natural range 0 to 1; cpol : in  natural range 0 to 1;
                              cpha : in natural range 0 to 1);


end package SimP;



package body SimP is


  -- wait for n rising edges on clk
  procedure wait_cycles (signal clk : in std_logic; n : in natural) is
  begin
    for i in 1 to n loop
      wait until rising_edge(clk);
    end loop;
  end procedure wait_cycles;


  -- configurable spi master which supports all combinations of cpol & cpha
  procedure spi_master (    data_in : in    std_logic_vector;   data_out : out std_logic_vector;
                        signal sclk : inout std_logic;        signal ste : out std_logic;
                        signal mosi : out   std_logic;       signal miso : in  std_logic;
                                dir : in    natural range 0 to 1;   cpol : in  natural range 0 to 1;
                               cpha : in  natural range 0 to 1;   period : in  time) is
  begin
    assert_equal(data_in'length, data_out'length, spi_master'simple_name & ": data_in & data_out must have same length!");
    sclk <= std_logic'val(cpol+2);
    ste  <= '0';
    if (cpha = 0) then
      for i in data_in'range loop
        if (dir = 0) then
          mosi <= data_in(data_in'high - i);
        else
          mosi <= data_in(i);
        end if;
        wait for period/2;
        sclk <= not(sclk);
        if (dir = 0) then
          data_out(data_out'high - i) := miso;
        else
          data_out(i) := miso;
        end if;
        wait for period/2;
        sclk <= not(sclk);
      end loop;
      wait for period/2;
    else
      mosi <= '1';
      wait for period/2;
      for i in data_in'range loop
        sclk <= not(sclk);
        if (dir = 0) then
          mosi <= data_in(data_in'high - i);
        else
          mosi <= data_in(i);
        end if;
        wait for period/2;
        sclk <= not(sclk);
        if (dir = 0) then
          data_out(data_out'high - i) := miso;
        else
          data_out(i) := miso;
        end if;
        wait for period/2;
      end loop;
    end if;
    ste  <= '1';
    mosi <= '1';
    wait for period/2;
  end procedure spi_master;


  -- configurable spi slave which supports all combinations of cpol & cpha
  procedure spi_slave (    data_in : in std_logic_vector; data_out : out std_logic_vector;
                       signal sclk : in std_logic;      signal ste : in  std_logic;
                       signal mosi : in std_logic;     signal miso : out std_logic;
                              dir  : in natural range 0 to 1; cpol : in  natural range 0 to 1;
                              cpha : in natural range 0 to 1) is
    variable v_cpol   : std_logic := std_logic'val(cpol+2);
  begin
    assert_equal(data_in'length, data_out'length, spi_slave'simple_name & ": data_in & data_out must have same length!");
    miso <= 'Z';
    wait until ste = '0';
    if (cpha = 0) then
      for i in data_in'range loop
        if (dir = 0) then
          miso <= data_in(data_in'high - i);
        else
          miso <= data_in(i);
        end if;
        wait until sclk'event and sclk = not(v_cpol);
        if (dir = 0) then
          data_out(data_out'high - i) := mosi;
        else
          data_out(i) := mosi;
        end if;
        wait until sclk'event and sclk = v_cpol;
      end loop;
    else
      for i in data_in'range loop
        wait until sclk'event and sclk = not(v_cpol);
        if (dir = 0) then
          miso <= data_in(data_in'high - i);
        else
          miso <= data_in(i);
        end if;
        wait until sclk'event and sclk = v_cpol;
        if (dir = 0) then
          data_out(data_out'high - i) := mosi;
        else
          data_out(i) := mosi;
        end if;
      end loop;
    end if;
    wait until ste = '1';
    miso <= 'Z';
  end procedure spi_slave;


end package body SimP;

library ieee;
  use ieee.std_logic_1164.all;

library libvhdl;
  use libvhdl.AssertP.all;



package SimP is


  procedure wait_cycles (signal clk : in std_logic; n : in natural);

  procedure spi_master (    data_in : in    std_logic_vector; data_out : out std_logic_vector;
                        signal sclk : inout std_logic;      signal ste : out std_logic;
                        signal mosi : out   std_logic;     signal miso : in  std_logic;
                               cpol : in    natural range 0 to 1; cpha : in  natural range 0 to 1;
                             period : in    time);

  procedure spi_slave (    data_in : in std_logic_vector; data_out : out std_logic_vector;
                       signal sclk : in std_logic;      signal ste : in  std_logic;
                       signal mosi : in std_logic;     signal miso : out std_logic;
                       cpol        : in natural range 0 to 1; cpha : in  natural range 0 to 1);


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
                               cpol : in    natural range 0 to 1;   cpha : in  natural range 0 to 1;
                             period : in    time) is
  begin
    assert_equal(data_in'length, data_out'length, "data_in & data_out must have same length!");
    sclk <= std_logic'val(cpol+2);
    ste  <= '0';
    if (cpha = 0) then
      for i in data_in'range loop
        mosi <= data_in(i);
        wait for period;
        sclk <= not(sclk);
        data_out(i) := miso;
        wait for period;
        sclk <= not(sclk);
      end loop;
      wait for period;
    else
      mosi <= '1';
      wait for period;
      for i in data_in'range loop
        sclk <= not(sclk);
        mosi <= data_in(i);
        wait for period;
        sclk <= not(sclk);
        data_out(i) := miso;
        wait for period;
      end loop;
    end if;
    ste  <= '1';
    mosi <= '1';
    wait for period;
  end procedure spi_master;


  -- configurable spi slave which supports all combinations of cpol & cpha
  procedure spi_slave (    data_in : in std_logic_vector; data_out : out std_logic_vector;
                       signal sclk : in std_logic;      signal ste : in  std_logic;
                       signal mosi : in std_logic;     signal miso : out std_logic;
                              cpol : in natural range 0 to 1; cpha : in  natural range 0 to 1) is
    variable v_cpol : std_logic := std_logic'val(cpol+2);
  begin
    assert_equal(data_in'length, data_out'length, "data_in & data_out must have same length!");
    miso <= 'Z';
    wait until ste = '0';
    if (cpha = 0) then
      for i in data_in'range loop
        miso <= data_in(i);
        wait until sclk'event and sclk = not(v_cpol);
        data_out(i) := mosi;
        wait until sclk'event and sclk = v_cpol;
      end loop;
    else
      for i in data_in'range loop
        wait until sclk'event and sclk = not(v_cpol);
        miso <= data_in(i);
        wait until sclk'event and sclk = v_cpol;
        data_out(i) := mosi;
      end loop;
    end if;
    wait until ste = '1';
    miso <= 'Z';
  end procedure spi_slave;


end package body SimP;

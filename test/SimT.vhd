library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

--+ including vhdl 2008 libraries
library ieee_proposed;
  use ieee_proposed.standard_additions.all;
  use ieee_proposed.std_logic_1164_additions.all;
  use ieee_proposed.numeric_std_additions.all;

library libvhdl;
  use libvhdl.AssertP.all;
  use libvhdl.SimP.all;



entity SimT is
end entity SimT;



architecture sim of SimT is


  constant C_PERIOD : time := 5 ns;

  signal s_tests_done : boolean_vector(0 to 1) := (others => false);

  signal s_clk  : std_logic := '0';

  signal s_sclk : std_logic;
  signal s_ste  : std_logic;
  signal s_mosi : std_logic;
  signal s_miso : std_logic;


begin


  s_clk <= not(s_clk) after C_PERIOD when not(and_reduce(s_tests_done)) else '0';


  SimTestP : process is
    variable v_time : time;
  begin
    wait until s_clk = '1';
    v_time := now;
    wait_cycles(s_clk, 10);
    assert (now - v_time) = C_PERIOD * 20
      severity failure;
    s_tests_done(0) <= true;
    wait;
  end process SimTestP;


  -- Unit test of spi master procedure, checks all combinations
  -- of cpol & cpha against spi slave procedure
  SpiMasterP : process is
    variable v_slave_data : std_logic_vector(7 downto 0);
  begin
    for mode in 0 to 3 loop
      for i in 0 to 255 loop
        spi_master (data_in  => std_logic_vector(to_unsigned(i, 8)),
                    data_out => v_slave_data,
                    sclk     => s_sclk,
                    ste      => s_ste,
                    mosi     => s_mosi,
                    miso     => s_miso,
                    cpol     => mode / 2,
                    cpha     => mode mod 2,
                    period   => 1 us
        );
        assert_equal(v_slave_data, std_logic_vector(to_unsigned(i, 8)));
      end loop;
    end loop;
    wait;
  end process SpiMasterP;


  -- Unit test of spi slave procedure, checks all combinations
  -- of cpol & cpha against spi master procedure
  SpiSlaveP : process is
    variable v_master_data : std_logic_vector(7 downto 0);
  begin
    for mode in 0 to 3 loop
      for i in 0 to 255 loop
        spi_slave (data_in  => std_logic_vector(to_unsigned(i, 8)),
                   data_out => v_master_data,
                   sclk     => s_sclk,
                   ste      => s_ste,
                   mosi     => s_mosi,
                   miso     => s_miso,
                   cpol     => mode / 2,
                   cpha     => mode mod 2
        );
        assert_equal(v_master_data, std_logic_vector(to_unsigned(i, 8)));
      end loop;
    end loop;
    report "INFO: SimP tests finished successfully";
    s_tests_done(1) <= true;
    wait;
  end process SpiSlaveP;


end architecture sim;

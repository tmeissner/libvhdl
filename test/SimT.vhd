library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library libvhdl;
  use libvhdl.StringP.all;
  use libvhdl.AssertP.all;
  use libvhdl.SimP.all;



entity SimT is
end entity SimT;



architecture sim of SimT is


  constant C_PERIOD : time := 5 ns;

  signal s_done : boolean := false;

  signal s_clk  : std_logic := '0';

  signal s_sclk : std_logic;
  signal s_ste  : std_logic;
  signal s_mosi : std_logic;
  signal s_miso : std_logic;


begin


  s_clk <= not(s_clk) after C_PERIOD when not(s_done) else '0';


  SimTestP : process is
    variable v_time : time;
  begin
    wait until s_clk = '1';
    v_time := now;
    wait_cycles(s_clk, 10);
    assert (now - v_time) = C_PERIOD * 20
      severity failure;
    s_done <= true;
    wait;
  end process SimTestP;


  SpiMasterP : process is
    variable v_slave_data : std_logic_vector(7 downto 0);
  begin
    for i in 0 to 255 loop
      spi_master (data_in  => std_logic_vector(to_unsigned(i, 8)),
                  data_out => v_slave_data,
                  sclk     => s_sclk,
                  ste      => s_ste,
                  mosi     => s_mosi,
                  miso     => s_miso,
                  cpol     => 1,
                  period   => 1 us
      );
      assert_equal(v_slave_data, std_logic_vector(to_unsigned(i, 8)));
    end loop;
    wait;
  end process SpiMasterP;


  SpiSlaveP : process is
    variable v_master_data : std_logic_vector(7 downto 0);
  begin
    for i in 0 to 255 loop
      spi_slave (data_in  => std_logic_vector(to_unsigned(i, 8)),
                 data_out => v_master_data,
                 sclk     => s_sclk,
                 ste      => s_ste,
                 mosi     => s_mosi,
                 miso     => s_miso,
                 cpol     => 1
      );
      assert_equal(v_master_data, std_logic_vector(to_unsigned(i, 8)));
    end loop;
    wait;
    report "INFO: SimP tests finished successfully";
  end process SpiSlaveP;


end architecture sim;

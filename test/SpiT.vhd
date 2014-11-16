library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library libvhdl;
  use libvhdl.StringP.all;
  use libvhdl.AssertP.all;
  use libvhdl.SimP.all;



entity SpiT is
end entity SpiT;



architecture sim of SpiT is


  component SpiSlaveE is
    generic (
      G_DATA_WIDTH : positive := 8;
      G_SPI_CPOL   : natural range 0 to 1 := 0;
      G_SPI_CPHA   : natural range 0 to 1 := 0
    );
    port (
      --+ system if
      Reset_n_i    : in  std_logic;
      Clk_i        : in  std_logic;
      --+ SPI slave if
      SpiSclk_i    : in  std_logic;
      SpiSte_i     : in  std_logic;
      SpiMosi_i    : in  std_logic;
      SpiMiso_o    : out std_logic;
      --+ local VAI if
      Data_i       : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
      DataValid_i  : in  std_logic;
      DataAccept_o : out std_logic;
      Data_o       : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
      DataValid_o  : out std_logic;
      DataAccept_i : in  std_logic
    );
  end component SpiSlaveE;


  constant C_PERIOD     : time := 5 ns;
  constant C_DATA_WIDTH : natural := 8;

  signal s_done : boolean := false;

  signal s_clk     : std_logic := '0';
  signal s_reset_n : std_logic := '0';

  signal s_sclk : std_logic;
  signal s_ste  : std_logic;
  signal s_mosi : std_logic;
  signal s_miso : std_logic;

  subtype t_spi_mode is natural range 0 to 3;
  signal s_spi_mode : t_spi_mode;


begin


  s_clk <= not(s_clk) after C_PERIOD when not(s_done) else '0';
  s_reset_n <= '1' after 100 ns;


  -- Unit test of spi master procedure, checks all combinations
  -- of cpol & cpha against spi slave procedure
  SpiMasterP : process is
    variable v_slave_data : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  begin
    s_sclk     <= '1';
    s_ste      <= '1';
    s_mosi     <= '1';
    s_spi_mode <= 0;
    wait until s_reset_n = '1';
    for mode in 0 to 3 loop
      s_spi_mode <= mode;
      for i in 0 to integer'(2**C_DATA_WIDTH-1) loop
        spi_master (data_in  => std_logic_vector(to_unsigned(i, C_DATA_WIDTH)),
                    data_out => v_slave_data,
                    sclk     => s_sclk,
                    ste      => s_ste,
                    mosi     => s_mosi,
                    miso     => s_miso,
                    cpol     => mode / 2,
                    cpha     => mode mod 2,
                    period   => 1 us
        );
        assert_equal(v_slave_data, std_logic_vector(to_unsigned(i, C_DATA_WIDTH)));
      end loop;
      report "INFO: SPI mode " & integer'image(mode) & " test successfully";
    end loop;
    report "INFO: SpiSlaveE tests finished successfully";
    s_done <= true;
    wait;
  end process SpiMasterP;


  --+ spi ste demultiplexing
  SpiSlavesG : for mode in t_spi_mode'low to t_spi_mode'high generate


    subtype t_control_array is std_logic_vector(t_spi_mode'low to t_spi_mode'high);
    signal s_spislave_ste : t_control_array;

    type t_data_array is array (t_spi_mode'low to t_spi_mode'high) of std_logic_vector(C_DATA_WIDTH-1 downto 0);

    signal s_din         : t_data_array;
    signal s_dout        : t_data_array;
    signal s_dout_valid  : t_control_array;
    signal s_dout_accept : t_control_array;


  begin


    s_din(mode) <= std_logic_vector(unsigned(s_dout(mode)) + 1);

    s_spislave_ste(mode) <= s_ste when s_spi_mode = mode else '1';

    i0_SpiSlaveE : SpiSlaveE
      generic map (
        G_DATA_WIDTH => 8,
        G_SPI_CPOL   => mode / 2,
        G_SPI_CPHA   => mode mod 2
      )
      port map (
        --+ system if
        Reset_n_i    => s_reset_n,
        Clk_i        => s_clk,
        --+ SPI slave if
        SpiSclk_i    => s_sclk,
        SpiSte_i     => s_spislave_ste(mode),
        SpiMosi_i    => s_mosi,
        SpiMiso_o    => s_miso,
        --+ local VAI if
        Data_i       => s_din(mode),
        DataValid_i  => s_dout_valid(mode),
        DataAccept_o => s_dout_accept(mode),
        Data_o       => s_dout(mode),
        DataValid_o  => s_dout_valid(mode),
        DataAccept_i => s_dout_accept(mode)
      );


  end generate SpiSlavesG;


end architecture sim;

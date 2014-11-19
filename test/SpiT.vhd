library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library libvhdl;
  use libvhdl.AssertP.all;
  use libvhdl.SimP.all;

--+ including vhdl 2008 libraries
library ieee_proposed;
  use ieee_proposed.standard_additions.all;
  use ieee_proposed.std_logic_1164_additions.all;
  use ieee_proposed.numeric_std_additions.all;



entity SpiT is
end entity SpiT;



architecture sim of SpiT is


  component SpiMasterE is
    generic (
      G_DATA_WIDTH   : positive := 8;
      G_SPI_CPOL     : natural range 0 to 1 := 0;
      G_SPI_CPHA     : natural range 0 to 1 := 0;
      G_SCLK_DIVIDER : positive := 10
    );
    port (
      --+ system if
      Reset_n_i    : in  std_logic;
      Clk_i        : in  std_logic;
      --+ SPI slave if
      SpiSclk_o    : out std_logic;
      SpiSte_o     : out std_logic;
      SpiMosi_o    : out std_logic;
      SpiMiso_i    : in  std_logic;
      --+ local VAI if
      Data_i       : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
      DataValid_i  : in  std_logic;
      DataAccept_o : out std_logic;
      Data_o       : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
      DataValid_o  : out std_logic;
      DataAccept_i : in  std_logic
    );
  end component SpiMasterE;


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


  --* testbench global clock period
  constant C_PERIOD     : time := 5 ns;
  --* SPI data transfer data width
  constant C_DATA_WIDTH : natural := 8;

  --* testbench global clock
  signal s_clk     : std_logic := '0';
  --* testbench global reset
  signal s_reset_n : std_logic := '0';

  --* SPI mode range subtype
  subtype t_spi_mode is natural range 0 to 3;

  --+ test done array with entry for each test
  signal s_test_done : boolean_vector(t_spi_mode'low to 2*t_spi_mode'high+1) := (others => false);


begin


  --* testbench global clock
  s_clk <= not(s_clk) after C_PERIOD/2 when not(and_reduce(s_test_done)) else '0';
  --* testbench global reset
  s_reset_n <= '1' after 100 ns;


    --+ spi ste demultiplexing
    SpiMastersG : for mode in t_spi_mode'low to t_spi_mode'high generate


      signal s_sclk : std_logic;
      signal s_ste  : std_logic;
      signal s_mosi : std_logic;
      signal s_miso : std_logic;

      signal s_din         : std_logic_vector(C_DATA_WIDTH-1 downto 0);
      signal s_din_valid   : std_logic;
      signal s_din_accept  : std_logic;
      signal s_dout        : std_logic_vector(C_DATA_WIDTH-1 downto 0);
      signal s_dout_valid  : std_logic;
      signal s_dout_accept : std_logic;


    begin


      SpiMasterStimP : process is
      begin
        wait until s_reset_n = '1';
        for i in 0 to integer'(2**C_DATA_WIDTH-1) loop
          s_din       <= std_logic_vector(to_unsigned(i, C_DATA_WIDTH));
          s_din_valid <= '1';
          wait until rising_edge(s_clk) and s_din_accept = '1';
          s_din_valid <= '0';
          wait until rising_edge(s_clk);
        end loop;
        wait;
      end process SpiMasterStimP;


      i_SpiMasterE : SpiMasterE
      generic map (
        G_DATA_WIDTH   => 8,
        G_SPI_CPOL     => mode / 2,
        G_SPI_CPHA     => mode mod 2,
        G_SCLK_DIVIDER => 10
      )
      port map (
        --+ system if
        Reset_n_i    => s_reset_n,
        Clk_i        => s_clk,
        --+ SPI slave if
        SpiSclk_o    => s_sclk,
        SpiSte_o     => s_ste,
        SpiMosi_o    => s_mosi,
        SpiMiso_i    => s_miso,
        --+ local VAI if
        Data_i       => s_din,
        DataValid_i  => s_din_valid,
        DataAccept_o => s_din_accept,
        Data_o       => s_dout,
        DataValid_o  => s_dout_valid,
        DataAccept_i => s_dout_accept
      );


      SpiMasterCheckP : process is
      begin
        wait until s_reset_n = '1';
        for i in 0 to integer'(2**C_DATA_WIDTH-1) loop
          wait until rising_edge(s_clk) and s_dout_valid = '1';
          s_dout_accept <= '1';
          assert_equal(s_dout, std_logic_vector(to_unsigned(i, C_DATA_WIDTH)));
          wait until rising_edge(s_clk);
          s_dout_accept <= '0';
        end loop;
        report "INFO: SpiMaster (mode=" & to_string(mode) & ") test successfully";
        s_test_done(mode) <= true;
        wait;
      end process SpiMasterCheckP;


      -- Unit test of spi slave procedure, checks all combinations
      -- of cpol & cpha against spi master procedure
      SpiSlaveP : process is
        variable v_master_data : std_logic_vector(7 downto 0) := (others => '0');
      begin
        for i in 0 to integer'(2**C_DATA_WIDTH-1) loop
          spi_slave (data_in  => v_master_data,
                     data_out => v_master_data,
                     sclk     => s_sclk,
                     ste      => s_ste,
                     mosi     => s_mosi,
                     miso     => s_miso,
                     cpol     => mode / 2,
                     cpha     => mode mod 2
          );
          assert_equal(v_master_data, std_logic_vector(to_unsigned(i, C_DATA_WIDTH)));
          v_master_data := std_logic_vector(unsigned(v_master_data) + 1);
        end loop;
        wait;
      end process SpiSlaveP;


    end generate SpiMastersG;




    --+ spi ste demultiplexing
    SpiSlavesG : for mode in t_spi_mode'low to t_spi_mode'high generate


      signal s_sclk : std_logic;
      signal s_ste  : std_logic;
      signal s_mosi : std_logic;
      signal s_miso : std_logic;

      signal s_din          : std_logic_vector(C_DATA_WIDTH-1 downto 0);
      signal s_dout         : std_logic_vector(C_DATA_WIDTH-1 downto 0);
      signal s_dout_valid   : std_logic;
      signal s_dout_accept  : std_logic;


    begin


      -- Unit test of spi master procedure, checks all combinations
      -- of cpol & cpha against spi slave procedure
      SpiMasterP : process is
        variable v_slave_data : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
      begin
        s_sclk     <= '1';
        s_ste      <= '1';
        s_mosi     <= '1';
        wait until s_reset_n = '1';
        for i in 0 to integer'(2**C_DATA_WIDTH-1) loop
          spi_master (data_in  => std_logic_vector(to_unsigned(i, C_DATA_WIDTH)),
                      data_out => v_slave_data,
                      sclk     => s_sclk,
                      ste      => s_ste,
                      mosi     => s_mosi,
                      miso     => s_miso,
                      cpol     => mode / 2,
                      cpha     => mode mod 2,
                      period   => 100 ns
          );
          assert_equal(v_slave_data, std_logic_vector(to_unsigned(i, C_DATA_WIDTH)));
        end loop;
        report "INFO: SpiSlave (mode=" & to_string(mode) & ") test successfully";
        s_test_done(mode+4) <= true;
        wait;
      end process SpiMasterP;


      s_din <= std_logic_vector(unsigned(s_dout) + 1);


      i_SpiSlaveE : SpiSlaveE
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
        SpiSte_i     => s_ste,
        SpiMosi_i    => s_mosi,
        SpiMiso_o    => s_miso,
        --+ local VAI if
        Data_i       => s_din,
        DataValid_i  => s_dout_valid,
        DataAccept_o => s_dout_accept,
        Data_o       => s_dout,
        DataValid_o  => s_dout_valid,
        DataAccept_i => s_dout_accept
      );


    end generate SpiSlavesG;



end architecture sim;

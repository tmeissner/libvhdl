library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

--+ including vhdl 2008 libraries
--+ These lines can be commented out when using
--+ a simulator with built-in VHDL 2008 support
library ieee_proposed;
  use ieee_proposed.standard_additions.all;
  use ieee_proposed.std_logic_1164_additions.all;
  use ieee_proposed.numeric_std_additions.all;

library osvvm;
  use osvvm.RandomPkg.all;

library libvhdl;
  use libvhdl.AssertP.all;
  use libvhdl.SimP.all;
  use libvhdl.QueueP.all;



entity SpiT is
end entity SpiT;



architecture sim of SpiT is


  component SpiMasterE is
    generic (
      G_DATA_WIDTH   : positive := 8;
      G_DATA_DIR     : natural range 0 to 1 := 0;
      G_SPI_CPOL     : natural range 0 to 1 := 0;
      G_SPI_CPHA     : natural range 0 to 1 := 0;
      G_SCLK_DIVIDER : positive range 6 to positive'high := 10
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
      G_DATA_DIR   : natural range 0 to 1 := 0;
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


  --+ SpiMasterE tests for all 4 modes
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

    shared variable sv_mosi_queue : t_list_queue;
    shared variable sv_miso_queue : t_list_queue;


  begin


    --* Stimuli generator and BFM for the valid-accept interface
    --* on the local data input of the DUT
    --*
    --* Generates random stimuli and serves it to the
    --* valid-accept interface at the input of the DUT
    --*
    --* The stimuli data is also pushed into the mosi queue
    --* which serves as simple abstract reference model
    --* of the SPI transmit (master -> slave) channel
    SpiMasterStimP : process is
      variable v_random : RandomPType;
    begin
      v_random.InitSeed(v_random'instance_name);
      s_din_valid <= '0';
      s_din       <= (others => '0');
      wait until s_reset_n = '1';
      for i in 0 to integer'(2**C_DATA_WIDTH-1) loop
        s_din <= v_random.RandSlv(C_DATA_WIDTH);
        s_din_valid <= '1';
        wait until rising_edge(s_clk) and s_din_accept = '1';
        s_din_valid <= '0';
        sv_mosi_queue.push(s_din);
        wait until rising_edge(s_clk);
      end loop;
      wait;
    end process SpiMasterStimP;


    --* DUT: SpiMasterE component
    i_SpiMasterE : SpiMasterE
    generic map (
      G_DATA_WIDTH   => C_DATA_WIDTH,
      G_DATA_DIR     => 1,
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


    --* Checker and BFM for the valid-accept interface
    --* on the local data output of the DUT
    --*
    --* Reads the output of the DUT and compares it to
    --* data popped from the miso queue which serves as
    --* simple abstract reference model of the SPI receive
    --* (slave -> master) channel
    SpiMasterCheckP : process is
      variable v_queue_data : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
    begin
      s_dout_accept <= '0';
      wait until s_reset_n = '1';
      for i in 0 to integer'(2**C_DATA_WIDTH-1) loop
        wait until rising_edge(s_clk) and s_dout_valid = '1';
        s_dout_accept <= '1';
        sv_miso_queue.pop(v_queue_data);
        assert_equal(s_dout, v_queue_data);
        wait until rising_edge(s_clk);
        s_dout_accept <= '0';
      end loop;
      report "INFO: SpiMaster (mode=" & to_string(mode) & ") test successfully";
      s_test_done(mode) <= true;
      wait;
    end process SpiMasterCheckP;


    --* Stimuli generator and BFM  for the SPI slave
    --* interface on the SPI miso input of the DUT
    --*
    --* Generates random stimuli and serves it to the
    --* SPI interface at the input of the DUT
    --*
    --* The stimuli data is also pushed into the miso queue
    --* which serves as simple abstract reference model
    --* of the SPI receive (slave -> master) channel
    --*
    --* Furthermore the data received by the SPI slave BFM
    --* is checked against data popped from the mosi queue
    --* which serves as simple abstract reference model of
    --* the SPI receive (master -> slave) channel
    SpiSlaveP : process is
      variable v_send_data    : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
      variable v_receive_data : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
      variable v_queue_data   : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
      variable v_random       : RandomPType;
    begin
      v_random.InitSeed(v_random'instance_name);
      wait until s_reset_n = '1';
      for i in 0 to integer'(2**C_DATA_WIDTH-1) loop
        v_send_data := v_random.RandSlv(C_DATA_WIDTH);
        sv_miso_queue.push(v_send_data);
        spi_slave (data_in  => v_send_data,
                   data_out => v_receive_data,
                   sclk     => s_sclk,
                   ste      => s_ste,
                   mosi     => s_mosi,
                   miso     => s_miso,
                   cpol     => mode / 2,
                   cpha     => mode mod 2
        );
        sv_mosi_queue.pop(v_queue_data);
        assert_equal(v_receive_data, v_queue_data);
      end loop;
      wait;
    end process SpiSlaveP;


  end generate SpiMastersG;



  --+ SpiSlaveE tests for all 4 modes
  SpiSlavesG : for mode in t_spi_mode'low to t_spi_mode'high generate


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

    shared variable sv_mosi_queue : t_list_queue;
    shared variable sv_miso_queue : t_list_queue;


  begin


    --* Unit test of spi master procedure, checks all combinations
    --* of cpol & cpha against spi slave procedure
    SpiMasterP : process is
      variable v_send_data    : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
      variable v_receive_data : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
      variable v_queue_data   : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
      variable v_random       : RandomPType;
    begin
      v_random.InitSeed(v_random'instance_name);
      s_sclk     <= '1';
      s_ste      <= '1';
      s_mosi     <= '1';
      wait until s_reset_n = '1';
      for i in 0 to integer'(2**C_DATA_WIDTH-1) loop
        v_send_data := v_random.RandSlv(C_DATA_WIDTH);
        sv_mosi_queue.push(v_send_data);
        spi_master (data_in  => v_send_data,
                    data_out => v_receive_data,
                    sclk     => s_sclk,
                    ste      => s_ste,
                    mosi     => s_mosi,
                    miso     => s_miso,
                    cpol     => mode / 2,
                    cpha     => mode mod 2,
                    period   => 100 ns
        );
        sv_miso_queue.pop(v_queue_data);
        assert_equal(v_receive_data, v_queue_data);
      end loop;
      report "INFO: SpiSlave (mode=" & to_string(mode) & ") test successfully";
      s_test_done(mode+4) <= true;
      wait;
    end process SpiMasterP;


    SpiSlaveStimP : process is
      variable v_random : RandomPType;
    begin
      v_random.InitSeed(v_random'instance_name);
      s_din_valid <= '0';
      s_din       <= (others => '0');
      wait until s_reset_n = '1';
      for i in 0 to integer'(2**C_DATA_WIDTH-1) loop
        s_din <= v_random.RandSlv(C_DATA_WIDTH);
        s_din_valid <= '1';
        wait until rising_edge(s_clk) and s_din_accept = '1';
        s_din_valid <= '0';
        sv_miso_queue.push(s_din);
        wait until rising_edge(s_clk) and s_dout_valid = '1';
      end loop;
      wait;
    end process SpiSlaveStimP;


    i_SpiSlaveE : SpiSlaveE
    generic map (
      G_DATA_WIDTH => C_DATA_WIDTH,
      G_DATA_DIR   => 1,
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
      DataValid_i  => s_din_valid,
      DataAccept_o => s_din_accept,
      Data_o       => s_dout,
      DataValid_o  => s_dout_valid,
      DataAccept_i => s_dout_accept
    );


    SpiSlaveCheckP : process is
      variable v_queue_data : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
    begin
      s_dout_accept <= '0';
      wait until s_reset_n = '1';
      for i in 0 to integer'(2**C_DATA_WIDTH-1) loop
        wait until rising_edge(s_clk) and s_dout_valid = '1';
        s_dout_accept <= '1';
        sv_mosi_queue.pop(v_queue_data);
        assert_equal(s_dout, v_queue_data);
        wait until rising_edge(s_clk);
        s_dout_accept <= '0';
      end loop;
      wait;
    end process SpiSlaveCheckP;


  end generate SpiSlavesG;



end architecture sim;

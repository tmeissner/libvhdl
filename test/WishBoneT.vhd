library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

--+ including vhdl 2008 libraries
--+ These lines can be commented out when using
--+ a simulator with built-in VHDL 2008 support
--library ieee_proposed;
--  use ieee_proposed.standard_additions.all;
--  use ieee_proposed.std_logic_1164_additions.all;
--  use ieee_proposed.numeric_std_additions.all;

library osvvm;
  use osvvm.RandomPkg.all;
  use osvvm.CoveragePkg.all;

library libvhdl;
  use libvhdl.AssertP.all;
  use libvhdl.SimP.all;
  use libvhdl.QueueP.all;
  use libvhdl.DictP.all;
  use libvhdl.UtilsP.all;



entity WishBoneT is
end entity WishBoneT;



architecture sim of WishBoneT is


  component WishBoneMasterE is
    generic (
      G_ADR_WIDTH  : positive := 8;  --* address bus width
      G_DATA_WIDTH : positive := 8   --* data bus width
    );
    port (
      --+ wishbone system if
      WbRst_i       : in  std_logic;
      WbClk_i       : in  std_logic;
      --+ wishbone outputs
      WbCyc_o       : out std_logic;
      WbStb_o       : out std_logic;
      WbWe_o        : out std_logic;
      WbAdr_o       : out std_logic_vector(G_ADR_WIDTH-1 downto 0);
      WbDat_o       : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
      --+ wishbone inputs
      WbDat_i       : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
      WbAck_i       : in  std_logic;
      WbErr_i       : in  std_logic;
      --+ local register if
      LocalWen_i    : in  std_logic;
      LocalRen_i    : in  std_logic;
      LocalAdress_i : in  std_logic_vector(G_ADR_WIDTH-1 downto 0);
      LocalData_i   : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
      LocalData_o   : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
      LocalAck_o    : out std_logic;
      LocalError_o  : out std_logic
    );
  end component WishBoneMasterE;


  component WishBoneSlaveE is
    generic (
      G_ADR_WIDTH  : positive := 8;  --* address bus width
      G_DATA_WIDTH : positive := 8   --* data bus width
    );
    port (
      --+ wishbone system if
      WbRst_i       : in  std_logic;
      WbClk_i       : in  std_logic;
      --+ wishbone inputs
      WbCyc_i       : in  std_logic;
      WbStb_i       : in  std_logic;
      WbWe_i        : in  std_logic;
      WbAdr_i       : in  std_logic_vector(G_ADR_WIDTH-1 downto 0);
      WbDat_i       : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
      --* wishbone outputs
      WbDat_o       : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
      WbAck_o       : out std_logic;
      WbErr_o       : out std_logic;
      --+ local register if
      LocalWen_o    : out std_logic;
      LocalRen_o    : out std_logic;
      LocalAdress_o : out std_logic_vector(G_ADR_WIDTH-1 downto 0);
      LocalData_o   : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
      LocalData_i   : in  std_logic_vector(G_DATA_WIDTH-1 downto 0)
    );
  end component WishBoneSlaveE;


  --* testbench global clock period
  constant C_PERIOD     : time := 5 ns;
  --* Wishbone data width
  constant C_DATA_WIDTH : natural := 8;
  --* Wishbone address width
  constant C_ADDRESS_WIDTH : natural := 8;

  --* testbench global clock
  signal s_wb_clk : std_logic := '1';
  --* testbench global reset
  signal s_wb_reset : std_logic := '1';

  --+ test done array with entry for each test
  signal s_test_done : boolean;


  signal s_wb_cyc              : std_logic;
  signal s_wb_stb              : std_logic;
  signal s_wb_we               : std_logic;
  signal s_wb_adr              : std_logic_vector(C_ADDRESS_WIDTH-1 downto 0);
  signal s_wb_master_data      : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal s_wb_slave_data       : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal s_wb_ack              : std_logic;
  signal s_wb_err              : std_logic;
  signal s_master_local_wen    : std_logic;
  signal s_master_local_ren    : std_logic;
  signal s_master_local_adress : std_logic_vector(C_ADDRESS_WIDTH-1 downto 0);
  signal s_master_local_din    : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal s_master_local_dout   : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal s_master_local_ack    : std_logic;
  signal s_master_local_error  : std_logic;
  signal s_slave_local_wen     : std_logic;
  signal s_slave_local_ren     : std_logic;
  signal s_slave_local_adress  : std_logic_vector(C_ADDRESS_WIDTH-1 downto 0);
  signal s_slave_local_dout    : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal s_slave_local_din     : std_logic_vector(C_DATA_WIDTH-1 downto 0);

  type t_register is array (0 to integer'(2**C_ADDRESS_WIDTH-1)) of std_logic_vector(C_DATA_WIDTH-1 downto 0);

  shared variable sv_wishbone_queue : t_list_queue;
  shared variable sv_wishbone_dict  : t_dict;
  shared variable sv_coverage       : CovPType;


begin


  --* testbench global clock
  s_wb_clk <= not(s_wb_clk) after C_PERIOD/2 when not(s_test_done) else '0';
  --* testbench global reset
  s_wb_reset <= '0' after C_PERIOD * 5;


  QueueInitP : process is
  begin
    sv_wishbone_queue.init(2**C_ADDRESS_WIDTH);
    sv_wishbone_dict.init(false);
    wait;
  end process QueueInitP;


  WbMasterLocalP : process is
    variable v_random           : RandomPType;
    variable v_wbmaster_address : integer;
    variable v_master_local_adress : std_logic_vector(C_ADDRESS_WIDTH-1 downto 0);
    variable v_wbmaster_data    : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    variable v_error            : t_dict_error;
  begin
    v_random.InitSeed(v_random'instance_name);
    v_wbmaster_data       := (others => '0');
    s_master_local_din    <= (others => '0');
    s_master_local_adress <= (others => '0');
    s_master_local_wen    <= '0';
    s_master_local_ren    <= '0';
    wait until s_wb_reset = '0';
    -- write the wishbone slave registers
    sv_coverage.AddBins(GenBin(0));
    sv_coverage.AddBins(GenBin(integer'(2**C_ADDRESS_WIDTH-1)));
    sv_coverage.AddBins(GenBin(1, integer'(2**C_ADDRESS_WIDTH-2), 64));
    while not sv_coverage.IsCovered loop
      v_wbmaster_address    := sv_coverage.RandCovPoint;
      v_wbmaster_data       := v_random.RandSlv(C_DATA_WIDTH);
      s_master_local_din    <= v_wbmaster_data;
      s_master_local_adress <= uint_to_slv(v_wbmaster_address, C_ADDRESS_WIDTH);
      s_master_local_wen    <= '1';
      wait until rising_edge(s_wb_clk);
      s_master_local_din    <= (others => '0');
      s_master_local_adress <= (others => '0');
      s_master_local_wen    <= '0';
      wait until rising_edge(s_wb_clk) and s_master_local_ack = '1';
      sv_wishbone_queue.push(uint_to_slv(v_wbmaster_address, C_ADDRESS_WIDTH));
      sv_wishbone_dict.set(integer'image(v_wbmaster_address), v_wbmaster_data, v_error);
      assert v_error = NO_ERROR
        report "ERROR: key error"
        severity failure;
      sv_coverage.ICover(v_wbmaster_address);
    end loop;
    -- read back and check the wishbone slave registers
    while not(sv_wishbone_queue.is_empty) loop
      sv_wishbone_queue.pop(v_master_local_adress);
      s_master_local_adress <= v_master_local_adress;
      s_master_local_ren    <= '1';
      wait until rising_edge(s_wb_clk);
      s_master_local_adress <= (others => '0');
      s_master_local_ren    <= '0';
      wait until rising_edge(s_wb_clk) and s_master_local_ack = '1';
      sv_wishbone_dict.get(integer'image(slv_to_uint(v_master_local_adress)), v_wbmaster_data, v_error);
      assert v_error = NO_ERROR
        report "ERROR: key error"
        severity failure;
      assert_equal(s_master_local_dout, v_wbmaster_data);
    end loop;
    -- test local write & read at the same time
    wait until rising_edge(s_wb_clk);
    s_master_local_wen    <= '1';
    s_master_local_ren    <= '1';
    wait until rising_edge(s_wb_clk);
    s_master_local_wen    <= '0';
    s_master_local_ren    <= '0';
    wait until rising_edge(s_wb_clk);
    -- Test finished
    report "INFO: Test successfully finished!";
    sv_coverage.SetMessage("WishboneT coverage results");
    sv_coverage.WriteBin;
    s_test_done <= true;
    wait;
  end process WbMasterLocalP;


  i_WishBoneMasterE : WishBoneMasterE
    generic map (
      G_ADR_WIDTH  => C_ADDRESS_WIDTH,
      G_DATA_WIDTH => C_DATA_WIDTH
    )
    port map (
      --+ wishbone system if
      WbRst_i       => s_wb_reset,
      WbClk_i       => s_wb_clk,
      --+ wishbone outputs
      WbCyc_o       => s_wb_cyc,
      WbStb_o       => s_wb_stb,
      WbWe_o        => s_wb_we,
      WbAdr_o       => s_wb_adr,
      WbDat_o       => s_wb_master_data,
      --+ wishbone inputs
      WbDat_i       => s_wb_slave_data,
      WbAck_i       => s_wb_ack,
      WbErr_i       => s_wb_err,
      --+ local register if
      LocalWen_i    => s_master_local_wen,
      LocalRen_i    => s_master_local_ren,
      LocalAdress_i => s_master_local_adress,
      LocalData_i   => s_master_local_din,
      LocalData_o   => s_master_local_dout,
      LocalAck_o    => s_master_local_ack,
      LocalError_o  => s_master_local_error
    );


    WishBoneBusMonitorP : process is
      variable v_master_local_adress : std_logic_vector(C_ADDRESS_WIDTH-1 downto 0);
      variable v_master_local_data   : std_logic_vector(C_DATA_WIDTH-1 downto 0);
      variable v_valid_access        : std_logic;
    begin
      wait until (s_master_local_wen = '1' or s_master_local_ren = '1') and rising_edge(s_wb_clk);
      v_master_local_adress := s_master_local_adress;
      v_master_local_data   := s_master_local_din;
      v_valid_access        := s_master_local_wen  xor s_master_local_ren;
      wait until rising_edge(s_wb_clk);
      WB_CYC : assert v_valid_access = s_wb_cyc
        report "ERROR: Wishbone cycle should be 0b" & to_string(v_valid_access) & " instead of 0b" & to_string(s_wb_cyc)
        severity failure;
      if (v_valid_access = '1') then
        WB_ADDR : assert s_wb_adr = v_master_local_adress
          report "ERROR: Wishbone address 0x" & to_hstring(s_wb_adr) & " differ from local address 0x" & to_hstring(v_master_local_adress)
          severity failure;
        if (s_wb_we = '1') then
          WB_DATA : assert s_wb_master_data = v_master_local_data
            report "ERROR: Wishbone data 0x" & to_hstring(s_wb_master_data) & " differ from local data 0x" & to_hstring(v_master_local_data)
            severity failure;
        end if;
      end if;
    end process WishBoneBusMonitorP;


   i_WishBoneSlaveE : WishBoneSlaveE
    generic map (
      G_ADR_WIDTH  => C_ADDRESS_WIDTH,
      G_DATA_WIDTH => C_DATA_WIDTH
    )
    port map (
      --+ wishbone system if
      WbRst_i       => s_wb_reset,
      WbClk_i       => s_wb_clk,
      --+ wishbone inputs
      WbCyc_i       => s_wb_cyc,
      WbStb_i       => s_wb_stb,
      WbWe_i        => s_wb_we,
      WbAdr_i       => s_wb_adr,
      WbDat_i       => s_wb_master_data,
      --* wishbone outputs
      WbDat_o       => s_wb_slave_data,
      WbAck_o       => s_wb_ack,
      WbErr_o       => s_wb_err,
      --+ local register if
      LocalWen_o    => s_slave_local_wen,
      LocalRen_o    => s_slave_local_ren,
      LocalAdress_o => s_slave_local_adress,
      LocalData_o   => s_slave_local_dout,
      LocalData_i   => s_slave_local_din
    );


    WbSlaveLocalP : process is
      variable v_register : t_register := (others => (others => '0'));
    begin
      wait until rising_edge(s_wb_clk);
      if (s_wb_reset = '1') then
        v_register        := (others => (others => '0'));
        s_slave_local_din <= (others => '0');
      else
        if (s_slave_local_wen = '1') then
          v_register(slv_to_uint(s_slave_local_adress)) := s_slave_local_dout;
        elsif (s_slave_local_ren = '1') then
          s_slave_local_din <= v_register(slv_to_uint(s_slave_local_adress));
        end if;
      end if;
    end process WbSlaveLocalP;


end architecture sim;

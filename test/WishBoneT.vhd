library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm;
  use osvvm.RandomPkg.all;
  use osvvm.CoveragePkg.all;

library libvhdl;
  use libvhdl.AssertP.all;
  use libvhdl.SimP.all;
  use libvhdl.UtilsP.all;

library work;
  use work.WishBoneP.all;

library std;
  use std.env.all;



entity WishBoneT is
end entity WishBoneT;



architecture sim of WishBoneT is


  --* testbench global clock period
  constant C_PERIOD     : time := 5 ns;
  --* Wishbone data width
  constant C_DATA_WIDTH : natural := 8;
  --* Wishbone address width
  constant C_ADDRESS_WIDTH : natural := 8;

  signal s_wishbone : t_wishbone_if(
    Adr(C_ADDRESS_WIDTH-1 downto 0),
    WDat(C_DATA_WIDTH-1 downto 0),
    RDat(C_DATA_WIDTH-1 downto 0)
    );

  --* testbench global clock
  signal s_wb_clk : std_logic := '1';
  --* testbench global reset
  signal s_wb_reset : std_logic := '1';

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


  package SlvQueue is new libvhdl.QueueP
    generic map (
      QUEUE_TYPE => std_logic_vector(C_ADDRESS_WIDTH-1 downto 0),
      MAX_LEN    => 2**C_ADDRESS_WIDTH,
      to_string  => to_hstring
    );

  shared variable sv_wishbone_queue : SlvQueue.t_list_queue;

  package IntSlvDict is new libvhdl.DictP
    generic map (KEY_TYPE        => natural,
                 VALUE_TYPE      => std_logic_vector,
                 key_to_string   => to_string,
                 value_to_string => to_hstring);

  shared variable sv_wb_master_dict : IntSlvDict.t_dict;
  shared variable sv_wb_slave_dict  : IntSlvDict.t_dict;

  shared variable sv_coverage      : CovPType;


begin


  --* testbench global clock
  s_wb_clk <= not(s_wb_clk) after C_PERIOD/2;
  --* testbench global reset
  s_wb_reset <= '0' after C_PERIOD * 5;


  QueueInitP : process is
  begin
    sv_wishbone_queue.init(false);
    sv_wb_master_dict.init(false);
    sv_wb_slave_dict.init(false);
    wait;
  end process QueueInitP;


  WbMasterLocalP : process is
    variable v_random           : RandomPType;
    variable v_wbmaster_address : integer;
    variable v_master_local_adress : std_logic_vector(C_ADDRESS_WIDTH-1 downto 0);
    variable v_wbmaster_data    : std_logic_vector(C_DATA_WIDTH-1 downto 0);
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
      sv_wb_master_dict.set(v_wbmaster_address, v_wbmaster_data);
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
      sv_wb_master_dict.get(slv_to_uint(v_master_local_adress), v_wbmaster_data);
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
    finish;
    wait;
  end process WbMasterLocalP;


  i_WishBoneMasterE : WishBoneMasterE
    generic map (
      Coverage     => false,
      Formal       => false,
      Simulation   => true,
      AddressWidth => C_ADDRESS_WIDTH,
      DataWidth    => C_DATA_WIDTH
    )
    port map (
      --+ wishbone system if
      WbRst_i       => s_wb_reset,
      WbClk_i       => s_wb_clk,
      --+ wishbone outputs
      WbCyc_o       => s_wishbone.Cyc,
      WbStb_o       => s_wishbone.Stb,
      WbWe_o        => s_wishbone.We,
      WbAdr_o       => s_wishbone.Adr,
      WbDat_o       => s_wishbone.WDat,
      --+ wishbone inputs
      WbDat_i       => s_wishbone.RDat,
      WbAck_i       => s_wishbone.Ack,
      WbErr_i       => s_wishbone.Err,
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
    v_valid_access        := s_master_local_wen xor s_master_local_ren;
    wait until rising_edge(s_wb_clk);
    WB_CYC : assert v_valid_access = s_wishbone.Cyc
      report "ERROR: Wishbone cycle should be 0b" & to_string(v_valid_access) & " instead of 0b" & to_string(s_wishbone.Cyc)
      severity failure;
    if (v_valid_access = '1') then
      WB_ADDR : assert s_wishbone.Adr = v_master_local_adress
        report "ERROR: Wishbone address 0x" & to_hstring(s_wishbone.Adr) & " differ from local address 0x" & to_hstring(v_master_local_adress)
        severity failure;
      if (s_wishbone.We = '1') then
        WB_DATA : assert s_wishbone.WDat = v_master_local_data
          report "ERROR: Wishbone data 0x" & to_hstring(s_wishbone.WDat) & " differ from local data 0x" & to_hstring(v_master_local_data)
          severity failure;
      end if;
    end if;
  end process WishBoneBusMonitorP;


  i_WishBoneSlaveE : WishBoneSlaveE
    generic map (
      Formal       => false,
      Simulation   => true,
      AddressWidth => C_ADDRESS_WIDTH,
      DataWidth    => C_DATA_WIDTH
    )
    port map (
      --+ wishbone system if
      WbRst_i       => s_wb_reset,
      WbClk_i       => s_wb_clk,
      --+ wishbone inputs
      WbCyc_i       => s_wishbone.Cyc,
      WbStb_i       => s_wishbone.Stb,
      WbWe_i        => s_wishbone.We,
      WbAdr_i       => s_wishbone.Adr,
      WbDat_i       => s_wishbone.WDat,
      --* wishbone outputs
      WbDat_o       => s_wishbone.RDat,
      WbAck_o       => s_wishbone.Ack,
      WbErr_o       => s_wishbone.Err,
      --+ local register if
      LocalWen_o    => s_slave_local_wen,
      LocalRen_o    => s_slave_local_ren,
      LocalAdress_o => s_slave_local_adress,
      LocalData_o   => s_slave_local_dout,
      LocalData_i   => s_slave_local_din
    );


  WbSlaveLocalP : process is
  begin
    wait until rising_edge(s_wb_clk);
    if (s_wb_reset = '1') then
      s_slave_local_din <= (others => '0');
    else
      if (s_slave_local_wen = '1') then
        sv_wb_slave_dict.set(slv_to_uint(s_slave_local_adress), s_slave_local_dout);
      elsif (s_slave_local_ren = '1') then
        WB_SLAVE_REG : assert sv_wb_slave_dict.hasKey(slv_to_uint(s_slave_local_adress))
          report "ERROR: Requested register at addr 0x" & to_hstring(s_slave_local_adress) & " not written before"
          severity failure;
        s_slave_local_din <= sv_wb_slave_dict.get(slv_to_uint(s_slave_local_adress));
      end if;
    end if;
  end process WbSlaveLocalP;


i_WishBoneChecker : WishBoneCheckerE
  port map (
    --+ wishbone system if
    WbRst_i       => s_wb_reset,
    WbClk_i       => s_wb_clk,
    --+ wishbone outputs
    WbMCyc_i      => s_wishbone.Cyc,
    WbMStb_i      => s_wishbone.Stb,
    WbMWe_i       => s_wishbone.We,
    WbMAdr_i      => s_wishbone.Adr,
    WbMDat_i      => s_wishbone.WDat,
    --+ wishbone inputs
    WbSDat_i      => s_wishbone.RDat,
    WbSAck_i      => s_wishbone.Ack,
    WbSErr_i      => s_wishbone.Err,
    WbRty_i       => '0'
  );


end architecture sim;

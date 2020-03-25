library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;



entity WishBoneMasterE is
  generic (
    Coverage     : boolean := true;
    Formal       : boolean := true;
    AddressWidth : natural := 8;
    DataWidth    : natural := 8
  );
  port (
    --+ wishbone system if
    WbRst_i       : in  std_logic;
    WbClk_i       : in  std_logic;
    --+ wishbone outputs
    WbCyc_o       : out std_logic;
    WbStb_o       : out std_logic;
    WbWe_o        : out std_logic;
    WbAdr_o       : out std_logic_vector(AddressWidth-1 downto 0);
    WbDat_o       : out std_logic_vector(DataWidth-1 downto 0);
    --+ wishbone inputs
    WbDat_i       : in  std_logic_vector(DataWidth-1 downto 0);
    WbAck_i       : in  std_logic;
    WbErr_i       : in  std_logic;
    --+ local register if
    LocalWen_i    : in  std_logic;
    LocalRen_i    : in  std_logic;
    LocalAdress_i : in  std_logic_vector(AddressWidth-1 downto 0);
    LocalData_i   : in  std_logic_vector(DataWidth-1 downto 0);
    LocalData_o   : out std_logic_vector(DataWidth-1 downto 0);
    LocalAck_o    : out std_logic;
    LocalError_o  : out std_logic
  );
end entity WishBoneMasterE;



architecture rtl of WishBoneMasterE is


  type t_wb_master_fsm is (IDLE, ADDRESS, DATA);
  signal s_wb_master_fsm : t_wb_master_fsm;

  signal s_wb_wen : std_logic;


begin


  --+ Wishbone master control state machine
  WbMasterStatesP : process (WbClk_i) is
  begin
    if (rising_edge(WbClk_i)) then
      if (WbRst_i = '1') then
        s_wb_master_fsm <= IDLE;
      else
        WbReadC : case s_wb_master_fsm is

          when IDLE =>
            if ((LocalWen_i xor LocalRen_i) = '1') then
              s_wb_master_fsm <= ADDRESS;
            end if;

          when ADDRESS =>
            if (WbAck_i = '1' or WbErr_i = '1') then
              s_wb_master_fsm <= IDLE;
            else
              s_wb_master_fsm <= DATA;
            end if;

          when DATA =>
            if (WbErr_i = '1' or WbAck_i = '1') then
              s_wb_master_fsm <= IDLE;
            end if;

          when others  =>
            s_wb_master_fsm <= IDLE;

        end case;
      end if;
    end if;
  end process WbMasterStatesP;


  --+ combinatoral local register if outputs
  LocalData_o  <= WbDat_i when s_wb_master_fsm  = DATA else (others => '0');
  LocalError_o <= WbErr_i when s_wb_master_fsm /= IDLE else '0';
  LocalAck_o   <= WbAck_i when (s_wb_master_fsm = ADDRESS or s_wb_master_fsm = DATA) and WbErr_i = '0' else '0';

  --+ combinatoral wishbone if outputs
  WbStb_o <= '1'      when s_wb_master_fsm /= IDLE else '0';
  WbCyc_o <= '1'      when s_wb_master_fsm /= IDLE else '0';
  WbWe_o  <= s_wb_wen when s_wb_master_fsm /= IDLE else '0';


  --+ registered wishbone if outputs
  OutRegsP : process (WbClk_i) is
  begin
    if (rising_edge(WbClk_i)) then
      if (WbRst_i = '1') then
        WbAdr_o  <= (others => '0');
        WbDat_o  <= (others => '0');
        s_wb_wen <= '0';
      else
        if (s_wb_master_fsm = IDLE) then
          if ((LocalWen_i xor LocalRen_i) = '1') then
            WbAdr_o  <= LocalAdress_i;
            s_wb_wen <= LocalWen_i;
          end if;
          if (LocalWen_i = '1') then
            WbDat_o <= LocalData_i;
          end if;
        end if;
      end if;
    end if;
  end process OutRegsP;


  FormalG : if Formal generate

    -- Glue logic
    signal s_local_data    : std_logic_vector(DataWidth-1 downto 0);
    signal s_local_address : std_logic_vector(AddressWidth-1 downto 0);

  begin

    process is
    begin
      wait until rising_edge(WbClk_i);
      if (s_wb_master_fsm = IDLE) then
        if (LocalWen_i = '1') then
          s_local_data    <= LocalData_i;
          s_local_address <= LocalAdress_i;
        end if;
        if (LocalRen_i = '1') then
          s_local_address <= LocalAdress_i;
        end if;
      end if;
    end process;


    default clock is rising_edge(WbClk_i);

    restrict {WbRst_i = '1'; WbRst_i = '0'[+]}[*1];

    RESET : assert always
      WbRst_i -> next
        WbCyc_o = '0' and WbStb_o = '0' and WbWe_o = '0' and
        to_integer(unsigned(WbAdr_o)) = 0 and to_integer(unsigned(WbDat_o)) = 0 and
        LocalAck_o = '0' and LocalError_o = '0' and to_integer(unsigned(LocalData_o)) = 0
        report "WB master: Reset error";

    WB_WRITE : assert always
      ((not WbCyc_o and not WbStb_o and LocalWen_i and not LocalRen_i) ->
        next (WbCyc_o and WbStb_o and WbWe_o)) abort WbRst_i
        report "WB master: Write error";

     WB_READ : assert always
       ((not WbCyc_o and not WbStb_o and LocalRen_i and not LocalWen_i) ->
         next (WbCyc_o and WbStb_o and not WbWe_o)) abort WbRst_i
         report "WB master: Read error";

    assert never LocalError_o and LocalAck_o;

    assert always WbStb_o = WbCyc_o;

    assert always
      not WbRst_i and WbCyc_o and not WbAck_i and not WbErr_i ->
      next (WbCyc_o until (WbAck_i or WbErr_i)) abort WbRst_i;

    assert always WbCyc_o and WbAck_i -> next not WbCyc_o;
    assert always WbWe_o and WbAck_i -> next not WbWe_o;
    assert always WbWe_o -> WbCyc_o;

    assert always WbWe_o -> WbDat_o = s_local_data abort WbRst_i;
    assert always WbWe_o -> WbAdr_o = s_local_address abort WbRst_i;

    assert always WbCyc_o and not WbWe_o -> WbAdr_o = s_local_address abort WbRst_i;

  end generate FormalG;


  CoverageG : if Coverage generate

    default clock is rising_edge(WbClk_i);

    restrict {WbRst_i = '1'; WbRst_i = '0'[+]}[*1];

    COVER_LOCAL_WRITE : cover {s_wb_master_fsm = IDLE and LocalWen_i = '1' and
      LocalRen_i = '0' and WbRst_i = '0'}
      report "WB master: Local write";

    COVER_LOCAL_READ : cover {s_wb_master_fsm = IDLE and LocalRen_i = '1' and
       LocalWen_i = '0' and WbRst_i = '0'}
      report "WB master: Local read";

    COVER_LOCAL_WRITE_READ : cover {s_wb_master_fsm = IDLE and LocalWen_i = '1' and
       LocalRen_i = '1' and WbRst_i = '0'}
      report "WB master: Local write & read";

    test_cover : cover {s_wb_master_fsm = IDLE and LocalWen_i = '1'; s_wb_master_fsm = ADDRESS; s_wb_master_fsm = DATA};

  end generate CoverageG;


end architecture rtl;

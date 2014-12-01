library ieee;
  use ieee.std_logic_1164.all;



entity WishBoneMasterE is
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
            if (LocalWen_i = '1' or LocalRen_i = '1') then
              s_wb_master_fsm <= ADDRESS;
            end if;

          when ADDRESS =>
            if (WbErr_i = '0') then
              s_wb_master_fsm <= DATA;
            else
              s_wb_master_fsm <= IDLE;
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
  LocalAck_o   <= WbAck_i when s_wb_master_fsm  = DATA and WbErr_i = '0' else '0';

  --+ combinatoral wishbone if outputs
  WbStb_o <= '1'      when s_wb_master_fsm /= IDLE else '0';
  WbCyc_o <= '1'      when s_wb_master_fsm /= IDLE else '0';
  WbWe_o  <= s_wb_wen when s_wb_master_fsm /= IDLE else '0';


  --+ registered wishbone if outputs
  OutRegsP : process (WbClk_i) is
  begin
    if(rising_edge(WbClk_i)) then
      if(WbRst_i = '1') then
        WbAdr_o  <= (others => '0');
        WbDat_o  <= (others => '0');
        s_wb_wen <= '0';
      else
        if (s_wb_master_fsm = IDLE) then
          if (LocalWen_i = '1' or LocalRen_i = '1') then
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


end architecture rtl;

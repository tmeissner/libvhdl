library ieee;
  use ieee.std_logic_1164.all;



package WishBoneP is



  component WishBoneMasterE is
    port (
      --+ wishbone system if
      WbRst_i       : in  std_logic;
      WbClk_i       : in  std_logic;
      --+ wishbone outputs
      WbCyc_o       : out std_logic;
      WbStb_o       : out std_logic;
      WbWe_o        : out std_logic;
      WbAdr_o       : out std_logic_vector;
      WbDat_o       : out std_logic_vector;
      --+ wishbone inputs
      WbDat_i       : in  std_logic_vector;
      WbAck_i       : in  std_logic;
      WbErr_i       : in  std_logic;
      --+ local register if
      LocalWen_i    : in  std_logic;
      LocalRen_i    : in  std_logic;
      LocalAdress_i : in  std_logic_vector;
      LocalData_i   : in  std_logic_vector;
      LocalData_o   : out std_logic_vector;
      LocalAck_o    : out std_logic;
      LocalError_o  : out std_logic
    );
  end component WishBoneMasterE;


  component WishBoneSlaveE is
    port (
      --+ wishbone system if
      WbRst_i       : in  std_logic;
      WbClk_i       : in  std_logic;
      --+ wishbone inputs
      WbCyc_i       : in  std_logic;
      WbStb_i       : in  std_logic;
      WbWe_i        : in  std_logic;
      WbAdr_i       : in  std_logic_vector;
      WbDat_i       : in  std_logic_vector;
      --* wishbone outputs
      WbDat_o       : out std_logic_vector;
      WbAck_o       : out std_logic;
      WbErr_o       : out std_logic;
      --+ local register if
      LocalWen_o    : out std_logic;
      LocalRen_o    : out std_logic;
      LocalAdress_o : out std_logic_vector;
      LocalData_o   : out std_logic_vector;
      LocalData_i   : in  std_logic_vector
    );
  end component WishBoneSlaveE;


  component WishBoneCheckerE is
    port (
      --+ wishbone system if
      WbRst_i       : in std_logic;
      WbClk_i       : in std_logic;
      --+ wishbone outputs
      WbMCyc_i      : in std_logic;
      WbMStb_i      : in std_logic;
      WbMWe_i       : in std_logic;
      WbMAdr_i      : in std_logic_vector;
      WbMDat_i      : in std_logic_vector;
      --+ wishbone inputs
      WbSDat_i      : in std_logic_vector;
      WbSAck_i      : in std_logic;
      WbSErr_i      : in std_logic;
      WbRty_i       : in std_logic
    );
  end component WishBoneCheckerE;


  type t_wishbone_if is record
    --+ wishbone outputs
    Cyc       : std_logic;
    Stb       : std_logic;
    We        : std_logic;
    Adr       : std_logic_vector;
    WDat      : std_logic_vector;
    --+ wishbone inputs
    RDat      : std_logic_vector;
    Ack       : std_logic;
    Err       : std_logic;
  end record t_wishbone_if;



end package WishBoneP;
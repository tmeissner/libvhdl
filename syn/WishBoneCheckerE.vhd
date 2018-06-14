library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;



entity WishBoneCheckerE is
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
    WbSErr_i      : in std_logic
  );
end entity WishBoneCheckerE;



architecture check of WishBoneCheckerE is

begin


  -- psl default clock is rising_edge(WbClk_i);
  --
  -- Wishbone protocol checks
  --
  -- psl property initialize(boolean init_state) is
  --   always ({WbRst_i} |=> {init_state[+] && {WbRst_i[*]; not(WbRst_i)}});
  --
  -- psl RULE_3_00 : assert initialize(not(WbMCyc_i) and not(WbMStb_i) and not(WbMWe_i))
  --   report "Wishbone rule 3.00 violated";
  --
  -- psl property reset_signal is
  --   always {not(WbRst_i); WbRst_i} |=> {(WbRst_i and not(WbClk_i))[*]; WbRst_i and WbClk_i};
  --
  -- psl RULE_3_05 : assert reset_signal
  --   report "Wishbone rule 3.05 violated";
  --
--  -- psl property master_cycle_signal(boolean master_strobe, master_cyc) is
--  --   always {master_strobe} |-> {master_cyc[+] && {not(master_strobe)[->]:WbClk_i}};
--  --
--  -- psl RULE_3_25 : assert master_cycle_signal(WbMStb_i, WbMCyc_i)
--  --   report "Wishbone rule 3.25 violated";


end architecture check;
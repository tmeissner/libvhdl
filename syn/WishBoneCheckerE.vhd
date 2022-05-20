--  Copyright (c) 2014 - 2022 by Torsten Meissner
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      https://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.



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
    WbSErr_i      : in std_logic;
    WbRty_i       : in std_logic
  );
end entity WishBoneCheckerE;



architecture check of WishBoneCheckerE is

begin


  -- psl default clock is rising_edge(WbClk_i);
  --
  -- Wishbone protocol checks
  --
  -- psl property initialize_interface (boolean init_state) is
  --   always ({WbRst_i} |=> {init_state[+] && {WbRst_i[*]; not(WbRst_i)}});
  --
  -- psl RULE_3_00 : assert initialize_interface (not(WbMCyc_i) and not(WbMStb_i) and not(WbMWe_i))
  --   report "Wishbone rule 3.00 violated";
  --
  -- psl property reset_signal is
  --   always {not(WbRst_i); WbRst_i} |=> {(WbRst_i and not(WbClk_i))[*]; WbRst_i and WbClk_i};
  --
  -- psl RULE_3_05 : assert reset_signal
  --   report "Wishbone rule 3.05 violated";
  --
  -- psl property CYC_O_signal is
  --   always {not(WbMStb_i); WbMStb_i} |-> {(WbMCyc_i and WbMStb_i)[+]; not(WbMStb_i)};
  --
  -- psl RULE_3_25 : assert CYC_O_signal
  --   report "Wishbone rule 3.25 violated";
  --
  -- psl property slave_no_response is
  --   always not(WbMCyc_i) -> not(WbSAck_i) and not(WbSErr_i);
  --
  -- psl property slave_response_to_master is
  --  always {not(WbMStb_i); WbMStb_i} |->
  --         {{(WbMStb_i and not(WbSAck_i))[*];
  --           WbMStb_i and WbSAck_i;
  --           not(WbMStb_i)} |
  --          {(WbMStb_i and not(WbSErr_i))[*];
  --           WbMStb_i and WbSErr_i;
  --           not(WbMStb_i)} |
  --          {(WbMStb_i and not(WbRty_i))[*];
  --           WbMStb_i and WbRty_i;
  --           not(WbMStb_i)}
  -- };
  --
  -- psl RULE_3_30_0 : assert slave_no_response
  --   report "Wishbone rule 3.30_0 violated";
  --
  -- psl RULE_3_30_1 : assert slave_response_to_master
  --   report "Wishbone rule 3.30_0 violated";
  --
  -- psl property slave_response is 
  --   always {not(WbMStb_i); WbMCyc_i and WbMStb_i} |->
  --     {not(WbSAck_i or WbSErr_i or WbRty_i)[*]; WbSAck_i or WbSErr_i or WbRty_i};
  --
  -- psl RULE_3_35 : assert slave_response
  --   report "Wishbone rule 3.35 violated";
  --
  -- psl property response_signals is
  --   never ((WbSErr_i and WbRty_i) or (WbSErr_i and WbSAck_i) or (WbSAck_i and WbRty_i));
  --
  -- psl RULE_3_45 : assert response_signals
  --   report "Wishbone rule 3.45 violated";
  --
  -- -- psl property slave_negated_response is


end architecture check;
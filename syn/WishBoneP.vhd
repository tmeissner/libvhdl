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



package WishBoneP is



  component WishBoneMasterE is
    generic (
      Coverage     : boolean := false;
      Formal       : boolean := false;
      Simulation   : boolean := false;
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
    generic (
      Formal       : boolean := false;
      Simulation   : boolean := false;
      AddressWidth : natural := 32;
      DataWidth    : natural := 32
    );
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
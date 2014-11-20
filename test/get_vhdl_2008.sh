#!/bin/bash

rm -rf vhdl_2008/*.vhdl
cd vhdl_2008

wget http://www.eda.org/fphdl/standard_additions_c.vhdl 
wget http://www.eda.org/fphdl/env_c.vhdl 
wget http://www.eda.org/fphdl/standard_textio_additions_c.vhdl 
wget http://www.eda.org/fphdl/std_logic_1164_additions.vhdl 
wget http://www.eda.org/fphdl/numeric_std_additions.vhdl
wget http://www.eda.org/fphdl/numeric_std_unsigned_c.vhdl 

patch < env_c.vhdl.patch

SIM_SRC = ../sim
SYN_SRC = ../syn
VHD_STD = 02

.PHONY: sim
sim: vhdl2008 osvvm queuet simt spit

.PHONY: vhdl2008
vhdl2008 : env_c.vhd numeric_std_additions.vhd numeric_std_unsigned_c.vhd standard_additions_c.vhd standard_textio_additions_c.vhd std_logic_1164_additions.vhd
	ghdl -a --std=$(VHD_STD) --work=ieee_proposed standard_additions_c.vhd standard_textio_additions_c.vhd std_logic_1164_additions.vhd numeric_std_additions.vhd numeric_std_unsigned_c.vhd env_c.vhd

.PHONY: osvvm
osvvm : vhdl2008 osvvm_2.1/SortListPkg_int.vhd osvvm_2.1/RandomBasePkg.vhd osvvm_2.1/RandomPkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm --ieee=synopsys osvvm_2.1/SortListPkg_int.vhd osvvm_2.1/RandomBasePkg.vhd osvvm_2.1/RandomPkg.vhd

queuet : QueueT.vhd $(SIM_SRC)/QueueP.vhd $(SIM_SRC)/AssertP.vhd
	ghdl -a --std=$(VHD_STD) --work=libvhdl $(SIM_SRC)/AssertP.vhd $(SIM_SRC)/QueueP.vhd
	ghdl -a --std=$(VHD_STD) QueueT.vhd
	ghdl -e --std=$(VHD_STD) QueueT
	ghdl -r --std=$(VHD_STD) QueueT

simt : vhdl2008 SimT.vhd $(SIM_SRC)/AssertP.vhd $(SIM_SRC)/SimP.vhd
	ghdl -a --std=$(VHD_STD) --work=libvhdl $(SIM_SRC)/AssertP.vhd $(SIM_SRC)/SimP.vhd
	ghdl -a --std=$(VHD_STD) SimT.vhd
	ghdl -e --std=$(VHD_STD) SimT
	ghdl -r --std=$(VHD_STD) SimT

spit : vhdl2008 osvvm SpiT.vhd $(SIM_SRC)/AssertP.vhd $(SIM_SRC)/SimP.vhd $(SIM_SRC)/QueueP.vhd $(SYN_SRC)/SpiSlaveE.vhd $(SYN_SRC)/SpiMasterE.vhd
	ghdl -a --std=$(VHD_STD) --work=libvhdl $(SIM_SRC)/AssertP.vhd $(SIM_SRC)/SimP.vhd $(SIM_SRC)/QueueP.vhd
	ghdl -a --std=$(VHD_STD) -fpsl $(SYN_SRC)/SpiSlaveE.vhd $(SYN_SRC)/SpiMasterE.vhd
	ghdl -a --std=$(VHD_STD) --ieee=synopsys -fpsl SpiT.vhd
	ghdl -e --std=$(VHD_STD) --ieee=synopsys SpiT
	ghdl -r --std=$(VHD_STD) SpiT --wave=spit.ghw

.PHONY: clean
clean:
	rm -f *.o
	rm -f *.cf
	rm -f *.ghw
	rm -f queuet
	rm -f stringt
	rm -f simt
	rm -f spit

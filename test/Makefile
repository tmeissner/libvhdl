SIM_SRC = ../sim
SYN_SRC = ../syn
VHD08_SRC = vhdl_2008
VHD_STD = 02

.PHONY: sim
sim: vhdl2008 osvvm queuet simt spit

.PHONY: vhdl2008
vhdl2008 : $(VHD08_SRC)/env_c.vhdl $(VHD08_SRC)/numeric_std_additions.vhdl $(VHD08_SRC)/numeric_std_unsigned_c.vhdl \
$(VHD08_SRC)/standard_additions_c.vhdl $(VHD08_SRC)/standard_textio_additions_c.vhdl $(VHD08_SRC)/std_logic_1164_additions.vhdl
	ghdl -a --std=$(VHD_STD) --work=ieee_proposed $(VHD08_SRC)/standard_additions_c.vhdl \
	$(VHD08_SRC)/standard_textio_additions_c.vhdl $(VHD08_SRC)/std_logic_1164_additions.vhdl $(VHD08_SRC)/numeric_std_additions.vhdl \
	$(VHD08_SRC)/numeric_std_unsigned_c.vhdl $(VHD08_SRC)/env_c.vhdl

.PHONY: osvvm
osvvm : vhdl2008 osvvm_2.1/SortListPkg_int.vhd osvvm_2.1/RandomBasePkg.vhd osvvm_2.1/RandomPkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm --ieee=synopsys osvvm_2.1/SortListPkg_int.vhd osvvm_2.1/RandomBasePkg.vhd osvvm_2.1/RandomPkg.vhd

queuet : vhdl2008 QueueT.vhd $(SIM_SRC)/QueueP.vhd $(SIM_SRC)/AssertP.vhd
	ghdl -a --std=$(VHD_STD) --work=libvhdl $(SIM_SRC)/AssertP.vhd $(SIM_SRC)/QueueP.vhd
	ghdl -a --std=$(VHD_STD) QueueT.vhd
	ghdl -e --std=$(VHD_STD) QueueT
	ghdl -r --std=$(VHD_STD) QueueT

simt : vhdl2008 osvvm SimT.vhd $(SIM_SRC)/QueueP.vhd $(SIM_SRC)/AssertP.vhd $(SIM_SRC)/SimP.vhd
	ghdl -a --std=$(VHD_STD) --work=libvhdl $(SIM_SRC)/QueueP.vhd $(SIM_SRC)/AssertP.vhd $(SIM_SRC)/SimP.vhd
	ghdl -a --std=$(VHD_STD) --ieee=synopsys SimT.vhd
	ghdl -e --std=$(VHD_STD) --ieee=synopsys SimT
	ghdl -r --std=$(VHD_STD) SimT

spit : vhdl2008 osvvm SpiT.vhd $(SIM_SRC)/AssertP.vhd $(SIM_SRC)/SimP.vhd $(SIM_SRC)/QueueP.vhd $(SYN_SRC)/SpiSlaveE.vhd $(SYN_SRC)/SpiMasterE.vhd
	ghdl -a --std=$(VHD_STD) --work=libvhdl $(SIM_SRC)/AssertP.vhd $(SIM_SRC)/SimP.vhd $(SIM_SRC)/QueueP.vhd
	ghdl -a --std=$(VHD_STD) -fpsl $(SYN_SRC)/SpiSlaveE.vhd $(SYN_SRC)/SpiMasterE.vhd
	ghdl -a --std=$(VHD_STD) --ieee=synopsys -fpsl SpiT.vhd
	ghdl -e --std=$(VHD_STD) --ieee=synopsys SpiT
	ghdl -r --std=$(VHD_STD) SpiT --wave=spit.ghw

wishbonet : vhdl2008 osvvm WishBoneT.vhd $(SYN_SRC)/WishBoneMasterE.vhd $(SYN_SRC)/WishBoneSlaveE.vhd
	ghdl -a --std=$(VHD_STD) --work=libvhdl $(SIM_SRC)/AssertP.vhd $(SIM_SRC)/SimP.vhd $(SIM_SRC)/QueueP.vhd
	ghdl -a --std=$(VHD_STD) -fpsl $(SYN_SRC)/WishBoneMasterE.vhd $(SYN_SRC)/WishBoneSlaveE.vhd
	ghdl -a --std=$(VHD_STD) --ieee=synopsys WishBoneT.vhd
	ghdl -e --std=$(VHD_STD) --ieee=synopsys WishBoneT
	ghdl -r --std=$(VHD_STD) --ieee=synopsys WishBoneT --wave=wishbonet.ghw

.PHONY: clean
clean:
	rm -f *.o
	rm -f *.cf
	rm -f *.ghw
	rm -f queuet
	rm -f stringt
	rm -f simt
	rm -f spit
	rm -f wishbonet

.PHONY: distclean
distclean: clean
	rm -f $(VHD08_SRC)/*.vhdl

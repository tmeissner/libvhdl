SIM_SRC := ../sim
SYN_SRC := ../syn
CMN_SRC := ../common
VHD08_SRC := vhdl_2008
VHD_STD := 08


.PHONY: all
all: queue dict stack sim wishbone


.PHONY: vhdl2008
vhdl2008 : $(VHD08_SRC)/env_c.vhdl $(VHD08_SRC)/numeric_std_additions.vhdl $(VHD08_SRC)/numeric_std_unsigned_c.vhdl \
$(VHD08_SRC)/standard_additions_c.vhdl $(VHD08_SRC)/standard_textio_additions_c.vhdl $(VHD08_SRC)/std_logic_1164_additions.vhdl
	ghdl -a --std=$(VHD_STD) --work=ieee_proposed $(VHD08_SRC)/standard_additions_c.vhdl \
	$(VHD08_SRC)/standard_textio_additions_c.vhdl $(VHD08_SRC)/std_logic_1164_additions.vhdl $(VHD08_SRC)/numeric_std_additions.vhdl \
	$(VHD08_SRC)/numeric_std_unsigned_c.vhdl $(VHD08_SRC)/env_c.vhdl


RandomPkg.o: OSVVM/SortListPkg_int.vhd OSVVM/RandomBasePkg.vhd OSVVM/RandomPkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $^

CoveragePkg.o: RandomPkg.o OSVVM/MessagePkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm OSVVM/MessagePkg.vhd OSVVM/CoveragePkg.vhd

UtilsP.o: $(CMN_SRC)/UtilsP.vhd
	ghdl -a --std=$(VHD_STD) --work=libvhdl $<


# Default rule for compiling packages
%P.o: $(SIM_SRC)/%P.vhd
	ghdl -a --std=$(VHD_STD) --work=libvhdl $<


queuet: AssertP.o QueueP.o QueueT.vhd
	ghdl -a --std=$(VHD_STD) QueueT.vhd
	ghdl -e --std=$(VHD_STD) $@


dictt: RandomPkg.o DictP.o DictT.vhd
	ghdl -a --std=$(VHD_STD) DictT.vhd
	ghdl -e --std=$(VHD_STD) $@

stackt: RandomPkg.o AssertP.o StackP.o StackT.vhd
	ghdl -a --std=$(VHD_STD) StackT.vhd
	ghdl -e --std=$(VHD_STD) $@

simt: RandomPkg.o UtilsP.o AssertP.o QueueP.o SimP.o SimT.vhd
	ghdl -a --std=$(VHD_STD) SimT.vhd
	ghdl -e --std=$(VHD_STD) $@


spit: RandomPkg.o UtilsP.o $(SYN_SRC)/SpiSlaveE.vhd $(SYN_SRC)/SpiMasterE.vhd SpiT.vhd
	ghdl -a --std=$(VHD_STD) -fpsl $(SYN_SRC)/SpiSlaveE.vhd $(SYN_SRC)/SpiMasterE.vhd
	ghdl -a --std=$(VHD_STD) -fpsl SpiT.vhd
	ghdl -e --std=$(VHD_STD) $@

.PHONY: spi
spi: spit
	ghdl -r --std=$(VHD_STD) $@t --wave=$@t.ghw


wishbonet: RandomPkg.o CoveragePkg.o AssertP.o SimP.o QueueP.o DictP.o UtilsP.o \
	  $(SYN_SRC)/WishBoneMasterE.vhd $(SYN_SRC)/WishBoneSlaveE.vhd WishBoneT.vhd
	ghdl -a --std=$(VHD_STD) -fpsl $(SYN_SRC)/WishBoneMasterE.vhd $(SYN_SRC)/WishBoneSlaveE.vhd
	ghdl -a --std=$(VHD_STD) -fpsl WishBoneT.vhd
	ghdl -e --std=$(VHD_STD) $@

.PHONY: wishbone
wishbone: wishbonet
	ghdl -r --std=$(VHD_STD) $@t --wave=$@t.ghw


# Default rule for running simulation
%: %t
	ghdl -r --std=$(VHD_STD) $@t


.PHONY: clean
clean:
	rm -f *.o
	rm -f *.cf
	rm -f *.ghw
	rm -f queuet
	rm -f dictt
	rm -f stackt
	rm -f stringt
	rm -f simt
	rm -f spit
	rm -f wishbonet

.PHONY: distclean
distclean: clean
	rm -f $(VHD08_SRC)/*.vhdl

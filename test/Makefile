SIM_SRC := ../sim
SYN_SRC := ../syn
CMN_SRC := ../common
OSVVM_SRC := ../lib/OSVVM
VHD08_SRC := vhdl_2008
VHD_STD := 08


.PHONY: all
all: queue dict stack sim wishbone


OsvvmContext.o: $(OSVVM_SRC)/*.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/NamePkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/OsvvmGlobalPkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/VendorCovApiPkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/TranscriptPkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/TextUtilPkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/AlertLogPkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/MessagePkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/SortListPkg_int.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/RandomBasePkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/RandomPkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/CoveragePkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/MemoryPkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/ScoreboardGenericPkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/ScoreboardPkg_slv.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/ScoreboardPkg_int.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/ResolutionPkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/TbUtilPkg.vhd
	ghdl -a --std=$(VHD_STD) --work=osvvm $(OSVVM_SRC)/OsvvmContext.vhd 


UtilsP.o: $(CMN_SRC)/UtilsP.vhd
	ghdl -a --std=$(VHD_STD) --work=libvhdl $<


# Default rule for compiling packages
%P.o: $(SIM_SRC)/%P.vhd
	ghdl -a --std=$(VHD_STD) --work=libvhdl $<


queuet: OsvvmContext.o AssertP.o QueueP.o QueueT.vhd
	ghdl -a --std=$(VHD_STD) QueueT.vhd
	ghdl -e --std=$(VHD_STD) $@


dictt: OsvvmContext.o DictP.o DictT.vhd
	ghdl -a --std=$(VHD_STD) DictT.vhd
	ghdl -e --std=$(VHD_STD) $@

stackt: OsvvmContext.o AssertP.o StackP.o StackT.vhd
	ghdl -a --std=$(VHD_STD) StackT.vhd
	ghdl -e --std=$(VHD_STD) $@

simt: OsvvmContext.o UtilsP.o AssertP.o QueueP.o SimP.o SimT.vhd
	ghdl -a --std=$(VHD_STD) SimT.vhd
	ghdl -e --std=$(VHD_STD) $@


spit: OsvvmContext.o UtilsP.o $(SYN_SRC)/SpiSlaveE.vhd $(SYN_SRC)/SpiMasterE.vhd SpiT.vhd
	ghdl -a --std=$(VHD_STD) -fpsl $(SYN_SRC)/SpiSlaveE.vhd $(SYN_SRC)/SpiMasterE.vhd
	ghdl -a --std=$(VHD_STD) -fpsl SpiT.vhd
	ghdl -e --std=$(VHD_STD) $@

.PHONY: spi
spi: spit
	ghdl -r --std=$(VHD_STD) $@t --wave=$@t.ghw


wishbonet: OsvvmContext.o AssertP.o SimP.o QueueP.o DictP.o UtilsP.o \
	  $(SYN_SRC)/WishBoneMasterE.vhd $(SYN_SRC)/WishBoneSlaveE.vhd WishBoneT.vhd
	ghdl -a --std=$(VHD_STD) -fpsl $(SYN_SRC)/WishBoneMasterE.vhd $(SYN_SRC)/WishBoneSlaveE.vhd
	ghdl -a --std=$(VHD_STD) -fpsl WishBoneT.vhd
	ghdl -e --std=$(VHD_STD) $@

.PHONY: wishbone
wishbone: wishbonet
	ghdl -r --std=$(VHD_STD) $@t --wave=$@t.ghw --psl-report=$@_psl_coverage.json


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
	rm -f *.json

.PHONY: distclean
distclean: clean

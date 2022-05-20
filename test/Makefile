SIM_SRC := ../sim
SYN_SRC := ../syn
CMN_SRC := ../common
OSVVM_DIR := ../lib/OSVVM
OSVVM_SRC := \
  $(OSVVM_DIR)/NamePkg.vhd \
  $(OSVVM_DIR)/OsvvmGlobalPkg.vhd \
  $(OSVVM_DIR)/VendorCovApiPkg.vhd \
  $(OSVVM_DIR)/TranscriptPkg.vhd \
  $(OSVVM_DIR)/TextUtilPkg.vhd \
  $(OSVVM_DIR)/AlertLogPkg.vhd \
  $(OSVVM_DIR)/MessagePkg.vhd \
  $(OSVVM_DIR)/SortListPkg_int.vhd \
  $(OSVVM_DIR)/RandomBasePkg.vhd \
  $(OSVVM_DIR)/RandomPkg.vhd \
  $(OSVVM_DIR)/CoveragePkg.vhd \
  $(OSVVM_DIR)/MemoryPkg.vhd \
  $(OSVVM_DIR)/ScoreboardGenericPkg.vhd \
  $(OSVVM_DIR)/ScoreboardPkg_slv.vhd \
  $(OSVVM_DIR)/ScoreboardPkg_int.vhd \
  $(OSVVM_DIR)/ResolutionPkg.vhd \
  $(OSVVM_DIR)/TbUtilPkg.vhd \
  $(OSVVM_DIR)/OsvvmContext.vhd
VHD08_SRC := vhdl_2008
VHD_STD := 08


.PHONY: all
all: queue dict stack sim wishbone uart spi


OsvvmContext.o: $(OSVVM_SRC)
	ghdl -a --std=$(VHD_STD) --work=osvvm -Wno-hide $(OSVVM_SRC)


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

spit: OsvvmContext.o UtilsP.o QueueP.o SimP.o $(SYN_SRC)/SpiSlaveE.vhd $(SYN_SRC)/SpiMasterE.vhd SpiT.vhd
	ghdl -a --std=$(VHD_STD) -fpsl $(SYN_SRC)/SpiSlaveE.vhd $(SYN_SRC)/SpiMasterE.vhd
	ghdl -a --std=$(VHD_STD) -fpsl SpiT.vhd
	ghdl -e --std=$(VHD_STD) $@

uartt: OsvvmContext.o UtilsP.o $(SYN_SRC)/UartTx.vhd $(SYN_SRC)/UartRx.vhd UartT.vhd
	ghdl -a --std=$(VHD_STD) -fpsl $(SYN_SRC)/UartTx.vhd $(SYN_SRC)/UartRx.vhd
	ghdl -a --std=$(VHD_STD) -fpsl UartT.vhd
	ghdl -e --std=$(VHD_STD) $@


.PHONY: spi
spi: spit
	ghdl -r --std=$(VHD_STD) $@t --wave=$@t.ghw

.PHONY: uart
uart: uartt
	ghdl -r --std=$(VHD_STD) $@t --wave=$@t.ghw


wishbonet: OsvvmContext.o AssertP.o SimP.o QueueP.o DictP.o UtilsP.o $(SYN_SRC)/WishBoneCheckerE.vhd \
	  $(SYN_SRC)/WishBoneP.vhd $(SYN_SRC)/WishBoneMasterE.vhd $(SYN_SRC)/WishBoneSlaveE.vhd WishBoneT.vhd
	ghdl -a --std=$(VHD_STD) -fpsl $(SYN_SRC)/WishBoneP.vhd
	ghdl -a --std=$(VHD_STD) -fpsl $(SYN_SRC)/WishBoneCheckerE.vhd $(SYN_SRC)/WishBoneMasterE.vhd $(SYN_SRC)/WishBoneSlaveE.vhd
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
	rm -f uartt
	rm -f wishbonet
	rm -f *.json

.PHONY: distclean
distclean: clean

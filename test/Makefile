##  Copyright (c) 2014 - 2022 by Torsten Meissner
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##      https://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.



SIM_SRC := ../sim
SYN_SRC := ../syn
CMN_SRC := ../common
OSVVM_DIR := ../lib/OSVVM
OSVVM_SRC := \
  $(OSVVM_DIR)/TextUtilPkg.vhd \
  $(OSVVM_DIR)/ResolutionPkg.vhd \
  $(OSVVM_DIR)/NamePkg.vhd \
  $(OSVVM_DIR)/OsvvmGlobalPkg.vhd \
  $(OSVVM_DIR)/VendorCovApiPkg.vhd \
  $(OSVVM_DIR)/TranscriptPkg.vhd \
  $(OSVVM_DIR)/AlertLogPkg.vhd \
  $(OSVVM_DIR)/NameStorePkg.vhd \
  $(OSVVM_DIR)/MessageListPkg.vhd \
  $(OSVVM_DIR)/SortListPkg_int.vhd \
  $(OSVVM_DIR)/RandomBasePkg.vhd \
  $(OSVVM_DIR)/RandomPkg.vhd \
  $(OSVVM_DIR)/RandomProcedurePkg.vhd \
  $(OSVVM_DIR)/CoveragePkg.vhd \
  $(OSVVM_DIR)/ScoreboardGenericPkg.vhd \
  $(OSVVM_DIR)/ScoreboardPkg_slv.vhd \
  $(OSVVM_DIR)/ScoreboardPkg_int.vhd \
  $(OSVVM_DIR)/ResizePkg.vhd \
  $(OSVVM_DIR)/MemoryPkg.vhd \
  $(OSVVM_DIR)/TbUtilPkg.vhd \
  $(OSVVM_DIR)/ReportPkg.vhd \
	$(OSVVM_DIR)/OsvvmTypesPkg.vhd \
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

spit: OsvvmContext.o UtilsP.o QueueP.o AssertP.o SimP.o $(SYN_SRC)/SpiSlaveE.vhd $(SYN_SRC)/SpiMasterE.vhd SpiT.vhd
	ghdl -a --std=$(VHD_STD) -fpsl $(SYN_SRC)/SpiSlaveE.vhd $(SYN_SRC)/SpiMasterE.vhd
	ghdl -a --std=$(VHD_STD) -fpsl SpiT.vhd
	ghdl -e --std=$(VHD_STD) $@

uartt: OsvvmContext.o UtilsP.o $(SYN_SRC)/UartTx.vhd $(SYN_SRC)/UartRx.vhd UartT.vhd
	ghdl -a --std=$(VHD_STD) -fpsl $(SYN_SRC)/UartTx.vhd $(SYN_SRC)/UartRx.vhd
	ghdl -a --std=$(VHD_STD) -fpsl UartT.vhd
	ghdl -e --std=$(VHD_STD) $@


.PHONY: spi
spi: spit
	ghdl -r --std=$(VHD_STD) $@t
	# --wave=$@t.ghw

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

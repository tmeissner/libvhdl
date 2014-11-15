SIM_SRC = ../sim
VHD_STD = 02

.PHONY: sim
sim: queuet stringt

queuet : QueueT.vhd $(SIM_SRC)/QueueP.vhd $(SIM_SRC)/StringP.vhd $(SIM_SRC)/AssertP.vhd
	ghdl -a --std=$(VHD_STD) --work=libvhdl $(SIM_SRC)/StringP.vhd $(SIM_SRC)/AssertP.vhd $(SIM_SRC)/QueueP.vhd
	ghdl -a --std=$(VHD_STD) QueueT.vhd
	ghdl -e --std=$(VHD_STD) QueueT
	ghdl -r --std=$(VHD_STD) QueueT

stringt : StringT.vhd $(SIM_SRC)/StringP.vhd $(SIM_SRC)/AssertP.vhd
	ghdl -a --std=$(VHD_STD) --work=libvhdl $(SIM_SRC)/StringP.vhd $(SIM_SRC)/AssertP.vhd
	ghdl -a --std=$(VHD_STD) StringT.vhd
	ghdl -e --std=$(VHD_STD) StringT
	ghdl -r --std=$(VHD_STD) StringT

.PHONY: clean
clean:
	rm -f *.o
	rm -f *.cf
	rm -f queuet
	rm -f stringt

SIM_SRC = ../sim
VHD_STD = 02

.PHONY: sim
sim: queuet

queuet : QueueT.vhd $(SIM_SRC)/QueueP.vhd
	ghdl -a --std=$(VHD_STD) $(SIM_SRC)/QueueP.vhd QueueT.vhd
	ghdl -e --std=$(VHD_STD) QueueT
	ghdl -r --std=$(VHD_STD) QueueT


.PHONY: clean
clean:
	rm -f *.o
	rm -f *.cf
	rm -f queuet

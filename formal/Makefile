.PHONY: all-cover all-bmc all-prove all
all: all-cover all-bmc all-prove
all-cover: WishBoneMasterE-cover WishBoneSlaveE-cover
all-bmc: WishBoneMasterE-bmc WishBoneSlaveE-bmc
all-prove: WishBoneMasterE-prove WishBoneSlaveE-prove


%-cover: ../syn/%.vhd %.sby
	mkdir -p work
	sby --yosys "yosys -m ghdl" -f -d work/$@ $(subst -cover,,$@).sby cover

%-bmc: ../syn/%.vhd %.sby
	mkdir -p work
	sby --yosys "yosys -m ghdl" -f -d work/$@ $(subst -bmc,,$@).sby bmc

%-prove: ../syn/%.vhd %.sby
	mkdir -p work
	sby --yosys "yosys -m ghdl" -f -d work/$@ $(subst -prove,,$@).sby prove


clean:
	rm -rf work

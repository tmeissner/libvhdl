.PHONY: all-cover all-prove all
all: all-cover all-prove
all-cover: WishBoneMasterE-cover WishBoneSlaveE-cover
all-prove: WishBoneMasterE-prove WishBoneSlaveE-prove


%-cover: ../syn/%.vhd %.sby
	mkdir -p work
	sby --yosys "yosys -m ghdl" -f -d work/$@ $(subst -cover,,$@).sby cover

%-prove: ../syn/%.vhd %.sby
	mkdir -p work
	sby --yosys "yosys -m ghdl" -f -d work/$@ $(subst -prove,,$@).sby prove


clean:
	rm -rf work

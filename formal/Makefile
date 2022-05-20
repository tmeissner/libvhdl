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

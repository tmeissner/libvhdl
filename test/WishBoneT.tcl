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



set signals [list]
lappend signals "top.WishBoneT.s_wb_reset"
lappend signals "top.WishBoneT.s_wb_clk"
lappend signals "top.WishBoneT.s_wishbone.cyc"
lappend signals "top.WishBoneT.s_wishbone.stb"
lappend signals "top.WishBoneT.s_wishbone.we"
lappend signals "top.WishBoneT.s_wishbone.ack"
lappend signals "top.WishBoneT.s_wishbone.adr"
lappend signals "top.WishBoneT.s_wishbone.wdat"
lappend signals "top.WishBoneT.s_wishbone.rdat"
set num_added [ gtkwave::addSignalsFromList $signals ]

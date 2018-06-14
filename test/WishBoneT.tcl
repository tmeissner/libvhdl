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

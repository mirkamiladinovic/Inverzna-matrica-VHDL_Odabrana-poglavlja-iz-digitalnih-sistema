transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -2008 -work work {D:/altera/13.0sp1/andjela/matrix_pkg.vhd}
vcom -2008 -work work {D:/altera/13.0sp1/andjela/inv4x4_block.vhd}
vcom -2008 -work work {D:/altera/13.0sp1/andjela/inv2x2.vhd}


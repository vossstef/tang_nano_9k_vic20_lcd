quit -sim

cd ./sim
if ![file exists "./sim.mpf"] {
 project new "." sim
 project addfile "./../../src/dac.vhd"
 project addfile "./../../src/gowin_rpll/gowin_rpll.vhd"
 project addfile "./../../src/gowin_prom/gowin_prom_basic.vhd"
 project addfile "./../../src/vic20_ps2_if.vhd"
 project addfile "./../../src/ps2kbd.vhd"
 project addfile "./../../src/T65_MCode.vhd"
 project addfile "./../../src/gowin_sp_2kb/gowin_sp_2kb.vhd"
 project addfile "./../../src/T65_ALU.vhd"
 project addfile "./../../src/gowin_dpb/gowin_dpb.vhd"
 project addfile "./../../src/vic20_dblscan.vhd"
 project addfile "./../../src/vic20.vhd"
 project addfile "./../../src/m6522.vhd"
 project addfile "./../../src/gowin_sp_1kb/gowin_sp_1kb.vhd"
 project addfile "./../../src/gowin_prom/gowin_prom_kernal.vhd"
 project addfile "./../../src/vic20_vic.vhd"
 project addfile "./../../src/T65_Pack.vhd"
 project addfile "./../../src/gowin_prom/gowin_prom_char.vhd"
 project addfile "./../../src/gowin_prom/gowin_prom_pacman.vhd"
 project addfile "./../../src/T65.vhd"
 project addfile "./../../tb/vic20_tb.vhd"

 if [file exists work] {
    vdel -lib work -all
   }
vlib work
vlib gw1n

vcom -work gw1n -2008 -autoorder -explicit \
"./../../tb/prim_sim.vhd" \
"./../../tb/prim_syn.vhd"

vcom -work work -2008 -autoorder -explicit \
 "./../../tb/vic20_tb.vhd" \
 "./../../src/gowin_prom/gowin_prom_char.vhd" \
 "./../../src/gowin_sp_1kb/gowin_sp_1kb.vhd" \
 "./../../src/gowin_rpll/gowin_rpll.vhd" \
 "./../../src/gowin_prom/gowin_prom_basic.vhd" \
 "./../../src/gowin_prom/gowin_prom_kernal.vhd" \
 "./../../src/gowin_prom/gowin_prom_pacman.vhd" \
 "./../../src/gowin_sp_2kb/gowin_sp_2kb.vhd" \
 "./../../src/gowin_dpb/gowin_dpb.vhd" \
 "./../../src/dac.vhd" \
 "./../../src/vic20_ps2_if.vhd" \
 "./../../src/ps2kbd.vhd" \
 "./../../src/T65_MCode.vhd" \
 "./../../src/T65_ALU.vhd" \
 "./../../src/vic20_dblscan.vhd" \
 "./../../src/vic20.vhd" \
 "./../../src/m6522.vhd" \
 "./../../src/vic20_vic.vhd" \
 "./../../src/T65_Pack.vhd" \
 "./../../src/T65.vhd"
} else {
 project open "./sim"
 project compileoutofdate
}

vsim -voptargs=+acc -gui -L gw1n work.vic20_tb
view wave

add wave -divider "Input Signals"
#add wave -logic 

add wave -divider "Result Interface"
#add wave -logic 
#add wave -radix hexadecimal 
add wave -r /*

onerror {resume}
quietly WaveActivateNextPane {} 0

configure wave -namecolwidth 420
configure wave -valuecolwidth 110
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns

configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0ns} {2000ns}

# get rid of annoying VHDL Warning messages about arithmetic operands
# and numeric_std warnings ...
quietly set StdArithNoWarnings 1
quietly set NumericStdNoWarnings 1

run 10 ms

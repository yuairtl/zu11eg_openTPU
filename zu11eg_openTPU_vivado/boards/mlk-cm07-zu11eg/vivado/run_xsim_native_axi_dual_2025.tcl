set root [file normalize [file join [file dirname [info script]] .. .. ..]]
set tool_bin [file dirname [info nameofexecutable]]
set xvlog [file join $tool_bin xvlog]
set xelab [file join $tool_bin xelab]
set xsim [file join $tool_bin xsim]
set glbl [file normalize [file join $tool_bin ../../../data/verilog/src/glbl.v]]
set stamp [clock seconds]
set out [file join $root build "xsim_zu11eg_native_axi_dual_$stamp"]
file mkdir $out
cd $out

set files [list \
  [file join $root rtl/zu11eg/otpu_native_fifo.sv] \
  [file join $root rtl/zu11eg/otpu_native_axi_ch.sv] \
  [file join $root rtl/zu11eg/otpu_native_axi_sys.sv] \
  [file join $root sim/vivado/tb_native_axi_dual.sv] \
  $glbl \
]

exec $xvlog -sv -d SYNTHESIS -relax -work work {*}$files >@stdout 2>@stderr
exec $xelab --relax -L xpm -L unisims_ver -L secureip \
  work.tb_native_axi_dual work.glbl -debug typical -s tb_native_axi_dual >@stdout 2>@stderr
set sim_log [exec $xsim tb_native_axi_dual -runall 2>@1]
puts $sim_log
if {![string match "*PASS tb_native_axi_dual*" $sim_log]} {
  error "XSIM native AXI dual-channel test did not report PASS"
}
puts "XSIM_NATIVE_AXI_DUAL_OK OUT=$out"

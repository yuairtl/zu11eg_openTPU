set root [file normalize [file join [file dirname [info script]] .. .. ..]]
set tool_bin [file dirname [info nameofexecutable]]
set xvlog [file join $tool_bin xvlog]
set xelab [file join $tool_bin xelab]
set xsim [file join $tool_bin xsim]
set stamp [clock seconds]
set out [file join $root build "xsim_zu11eg_fabric_smoke_$stamp"]
file mkdir $out
cd $out

set files [list \
  [file join $root rtl/vpu/otpu_fp.sv] \
  [file join $root rtl/vpu/otpu_fpipe.sv] \
  [file join $root rtl/top/otpu_pkg.sv] \
  [file join $root rtl/mem/otpu_dram.sv] \
  [file join $root rtl/mem/otpu_tmem.sv] \
  [file join $root rtl/mem/otpu_native_dram.sv] \
  [file join $root rtl/mem/otpu_actram.sv] \
  [file join $root rtl/seq/otpu_seq.sv] \
  [file join $root rtl/vpu/otpu_vtree.sv] \
  [file join $root rtl/dma/otpu_dma.sv] \
  [file join $root rtl/mxu/otpu_mxu.sv] \
  [file join $root rtl/tech/generic/otpu_tech_dsp.sv] \
  [file join $root rtl/tech/generic/otpu_tech_ram.sv] \
  [file join $root rtl/vpu/otpu_quant.sv] \
  [file join $root rtl/vpu/otpu_se_comp.sv] \
  [file join $root rtl/vpu/otpu_se_tail.sv] \
  [file join $root rtl/vpu/otpu_vpu.sv] \
  [file join $root rtl/top/otpu_coll.sv] \
  [file join $root rtl/exp/tmem_nocopy/otpu_tmem_model.sv] \
  [file join $root rtl/top/otpu_slice.sv] \
  [file join $root rtl/top/otpu_top.sv] \
  [file join $root rtl/shell/otpu_board.sv] \
  [file join $root rtl/shell/otpu_afifo.sv] \
  [file join $root rtl/shell/otpu_mem_ch.sv] \
  [file join $root rtl/shell/otpu_axi_split2.sv] \
  [file join $root rtl/shell/otpu_ctrl.sv] \
  [file join $root rtl/shell/otpu_trace.sv] \
  [file join $root rtl/zu11eg/otpu_axil_join.sv] \
  [file join $root rtl/zu11eg/otpu_native_fifo.sv] \
  [file join $root rtl/zu11eg/otpu_native_axi_ch.sv] \
  [file join $root rtl/zu11eg/otpu_native_axi_sys.sv] \
  [file join $root rtl/zu11eg/otpu_dci_reset.sv] \
  [file join $root rtl/boards/mlk-cm07-zu11eg/otpu_zu11eg_fabric.sv] \
  [file join $root sim/vivado/tb_zu11eg_fabric_smoke.sv] \
]

exec $xvlog -sv -relax -work work -i [file join $root rtl/top] {*}$files >@stdout 2>@stderr
exec $xelab --relax work.tb_zu11eg_fabric_smoke -debug typical -s tb_zu11eg_fabric_smoke >@stdout 2>@stderr
set sim_log [exec $xsim tb_zu11eg_fabric_smoke -runall 2>@1]
puts $sim_log
if {![string match "*PASS tb_zu11eg_fabric_smoke*" $sim_log]} {
  error "XSIM fabric smoke did not report PASS"
}
puts "XSIM_FABRIC_SMOKE_OK OUT=$out"

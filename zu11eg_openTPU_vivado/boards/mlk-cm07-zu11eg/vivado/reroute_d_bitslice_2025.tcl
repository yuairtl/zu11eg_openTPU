set routed_dcp [lindex $argv 0]
set out_dir [lindex $argv 1]
if {$routed_dcp eq "" || $out_dir eq ""} {
  error "usage: reroute_d_bitslice_2025.tcl <routed.dcp> <out-dir>"
}

file mkdir $out_dir
open_checkpoint $routed_dcp

# AMD known issue: reroute D[1]/D[2] on the failing RXTX_BITSLICE with
# the delay-aware router. This is the remaining WPWS pair in MIG1 byte 10.
set d_bitslice_upper {system_i/ddr4_1/inst/u_ddr4_mem_intfc/u_mig_ddr4_phy/inst/generate_block1.u_ddr_xiphy/byte_num[10].xiphy_byte_wrapper.u_xiphy_byte_wrapper/I_BITSLICE_UPPER[4].GEN_RXTX_BITSLICE_EN.u_xiphy_bitslice_upper/xiphy_rxtx_bitslice/D}
set myPins [get_pins [list ${d_bitslice_upper}\[2\] ${d_bitslice_upper}\[1\]]]
if {[llength $myPins] != 2} {
  error "expected two RXTX_BITSLICE D pins, found [llength $myPins]"
}
route_design -unroute -pins $myPins
route_design -pins $myPins -delay

report_timing_summary -delay_type min_max -max_paths 30 \
  -file [file join $out_dir timing_summary.rpt]
report_bus_skew -file [file join $out_dir bus_skew.rpt]
report_drc -file [file join $out_dir drc.rpt]
write_checkpoint -force [file join $out_dir system_wrapper_retry.dcp]
write_bitstream -force [file join $out_dir system_wrapper_retry.bit]
puts "REROUTE_D_BITSLICE_DONE pins=$myPins"
close_design
exit

set placed_dcp [lindex $argv 0]
set out_dir [lindex $argv 1]
if {$placed_dcp eq "" || $out_dir eq ""} {
  error "usage: route_explore_first_board_2025.tcl <placed.dcp> <out-dir>"
}

file mkdir $out_dir
open_checkpoint $placed_dcp
route_design -directive Explore
report_timing_summary -delay_type min_max -max_paths 30 \
  -file [file join $out_dir timing_summary.rpt]
report_bus_skew -file [file join $out_dir bus_skew.rpt]
report_drc -file [file join $out_dir drc.rpt]
report_cdc -details -file [file join $out_dir cdc.rpt]
write_checkpoint -force [file join $out_dir system_wrapper_explore_routed.dcp]
write_bitstream -force [file join $out_dir system_wrapper_explore.bit]
puts "ROUTE_EXPLORE_DONE"
close_design
exit

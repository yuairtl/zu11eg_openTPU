set routed_dcp [lindex $argv 0]
set out_dir [lindex $argv 1]
set directive [lindex $argv 2]
if {$routed_dcp eq "" || $out_dir eq "" || $directive eq ""} {
  error "usage: route_retry_first_board_2025.tcl <routed.dcp> <out-dir> <directive>"
}

file mkdir $out_dir
open_checkpoint $routed_dcp
route_design -directive $directive
report_timing_summary -delay_type min_max -max_paths 30 \
  -file [file join $out_dir timing_summary.rpt]
report_bus_skew -file [file join $out_dir bus_skew.rpt]
report_drc -file [file join $out_dir drc.rpt]
write_checkpoint -force [file join $out_dir system_wrapper_retry.dcp]
write_bitstream -force [file join $out_dir system_wrapper_retry.bit]
puts "ROUTE_RETRY_DONE directive=$directive"
close_design
exit

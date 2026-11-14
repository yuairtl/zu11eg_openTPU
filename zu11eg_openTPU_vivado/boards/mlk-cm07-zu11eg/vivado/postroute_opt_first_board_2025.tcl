set routed_dcp [lindex $argv 0]
set out_dir [lindex $argv 1]
if {$routed_dcp eq "" || $out_dir eq ""} {
  error "usage: postroute_opt_first_board_2025.tcl <routed.dcp> <out-dir>"
}

file mkdir $out_dir
open_checkpoint $routed_dcp

# Replicate and move only the logic the router could not meet, then reroute
# without relaxing timing. The MIG PHY is not floorplanned by this script.
phys_opt_design -directive AggressiveExplore
route_design -directive NoTimingRelaxation

report_timing_summary -delay_type min_max -max_paths 30 \
  -file [file join $out_dir timing_summary.rpt]
report_bus_skew -file [file join $out_dir bus_skew.rpt]
report_drc -file [file join $out_dir drc.rpt]
report_cdc -details -file [file join $out_dir cdc.rpt]
write_checkpoint -force [file join $out_dir system_wrapper_opt_routed.dcp]
write_bitstream -force [file join $out_dir system_wrapper_opt.bit]

set wns [get_property STATS.WNS [current_design]]
set tns [get_property STATS.TNS [current_design]]
set whs [get_property STATS.WHS [current_design]]
set wpws [get_property STATS.WPWS [current_design]]
puts "POSTROUTE_TIMING WNS=$wns TNS=$tns WHS=$whs WPWS=$wpws"
puts "POSTROUTE_OPT_DONE"
close_design
exit

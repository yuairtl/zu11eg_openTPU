set dcp_file [lindex $argv 0]
set report_dir [lindex $argv 1]
if {$dcp_file eq "" || $report_dir eq ""} {
  error "usage: report_first_board_placed_2025.tcl <placed.dcp> <report-dir>"
}

open_checkpoint $dcp_file
file mkdir $report_dir
report_clocks -file [file join $report_dir clocks.rpt]
report_clock_interaction -delay_type min_max \
  -file [file join $report_dir clock_interaction.rpt]
report_timing_summary -delay_type min_max -max_paths 30 \
  -path_type full_clock_expanded \
  -file [file join $report_dir timing_summary_placed.rpt]
report_timing -delay_type min -max_paths 30 \
  -path_type full_clock_expanded \
  -file [file join $report_dir timing_hold_placed.rpt]
report_timing -delay_type max -max_paths 30 \
  -path_type full_clock_expanded \
  -file [file join $report_dir timing_setup_placed.rpt]
report_bus_skew -file [file join $report_dir bus_skew_placed.rpt]
report_cdc -details -file [file join $report_dir cdc_placed.rpt]
report_drc -file [file join $report_dir drc_placed.rpt]
puts "PLACED_REPORT_OK"
close_design
exit

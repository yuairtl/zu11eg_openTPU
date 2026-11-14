# Read-only timing probe for a routed or post-physopt checkpoint.
# Required environment variable: OTPU_DCP
# Optional environment variable: OTPU_REPORT_DIR

if {![info exists ::env(OTPU_DCP)]} {
  error "OTPU_DCP is required"
}

set dcp_file $::env(OTPU_DCP)
if {[info exists ::env(OTPU_REPORT_DIR)]} {
  set report_dir $::env(OTPU_REPORT_DIR)
} else {
  set report_dir [file join [file dirname $dcp_file] timing_probe]
}
file mkdir $report_dir

open_checkpoint $dcp_file
if {[info exists ::env(OTPU_CONSTRAINT)]} {
  source $::env(OTPU_CONSTRAINT)
  update_timing -full
}
report_timing_summary -delay_type min_max -max_paths 20 \
  -file [file join $report_dir timing_summary.rpt]
report_timing -delay_type max -max_paths 30 -nworst 10 -path_type full_clock_expanded \
  -file [file join $report_dir timing_max.rpt]
report_timing -delay_type min -max_paths 30 -nworst 10 -path_type full_clock_expanded \
  -file [file join $report_dir timing_min.rpt]
check_timing -verbose -file [file join $report_dir check_timing.rpt]
report_exceptions -coverage -file [file join $report_dir exceptions.rpt]

puts "TIMING_PROBE DCP=$dcp_file REPORTS=$report_dir"
close_design
exit

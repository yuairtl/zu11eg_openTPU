# Read-only CDC probe for a routed checkpoint.
# Required environment variables: OTPU_DCP, OTPU_CDC_WAIVER
# Optional environment variable: OTPU_REPORT_DIR

if {![info exists ::env(OTPU_DCP)] || ![info exists ::env(OTPU_CDC_WAIVER)]} {
  error "OTPU_DCP and OTPU_CDC_WAIVER are required"
}

set dcp_file $::env(OTPU_DCP)
if {[info exists ::env(OTPU_REPORT_DIR)]} {
  set report_dir $::env(OTPU_REPORT_DIR)
} else {
  set report_dir [file join [file dirname $dcp_file] cdc_probe]
}
file mkdir $report_dir

open_checkpoint $dcp_file
source $::env(OTPU_CDC_WAIVER)
report_cdc -details -file [file join $report_dir cdc.rpt]
report_cdc -details -waived -file [file join $report_dir cdc_waived.rpt]

puts "CDC_PROBE DCP=$dcp_file REPORTS=$report_dir"
close_design
exit

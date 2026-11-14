set project_file [lindex $argv 0]
set final_bit [lindex $argv 1]
set final_dcp [lindex $argv 2]
set out_dir [lindex $argv 3]
if {$project_file eq "" || $final_bit eq "" || $final_dcp eq "" || $out_dir eq ""} {
  error "usage: export_final_xsa_2025.tcl <project.xpr> <bit> <routed.dcp> <out-dir>"
}

file mkdir $out_dir
open_project $project_file
set impl_dir [get_property DIRECTORY [get_runs impl_1]]
file copy -force $final_bit [file join $impl_dir system_wrapper.bit]
file copy -force $final_dcp [file join $impl_dir system_wrapper_routed.dcp]
set xsa [file join $out_dir opentpu_zu11eg_final.xsa]
write_hw_platform -fixed -include_bit -force $xsa
file copy -force $final_bit [file join $out_dir system_wrapper.bit]
file copy -force $final_dcp [file join $out_dir system_wrapper_routed.dcp]
puts "FINAL_XSA_DONE=$xsa"
close_project
exit

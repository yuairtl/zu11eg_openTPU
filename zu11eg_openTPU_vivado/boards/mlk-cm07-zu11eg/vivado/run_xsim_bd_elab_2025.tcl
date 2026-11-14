set root [file normalize [file join [file dirname [info script]] .. .. ..]]
set out [file join $root build "xsim_zu11eg_bd_elab_[clock seconds]"]
file mkdir $out

if {![info exists ::env(OTPU_BD_PROJECT)]} {
  error "OTPU_BD_PROJECT must point to opentpu_zu11eg.xpr"
}
open_project $::env(OTPU_BD_PROJECT)
set bd [lindex [get_files -quiet */bd/system/system.bd] 0]
if {$bd eq ""} {
  error "system.bd not found"
}
generate_target all [get_files $bd]
export_ip_user_files -of_objects [get_files $bd] -force -no_script
report_ip_status -file [file join $out ip_status.rpt]

set afifo [file join $root rtl/shell/otpu_afifo.sv]
if {[llength [get_files -quiet $afifo]] == 0} {
  error "otpu_afifo.sv is missing from the project"
}
set_property IS_ENABLED 1 [get_files $afifo]

if {[llength [get_filesets -quiet sim_1]] == 0} {
  create_fileset -simset sim_1
}
set tb_name [expr {[info exists ::env(OTPU_BD_TB)] ? $::env(OTPU_BD_TB) : "tb_system_wrapper_smoke.sv"}]
set tb_top [expr {[info exists ::env(OTPU_BD_TB_TOP)] ? $::env(OTPU_BD_TB_TOP) : "tb_system_wrapper_smoke"}]
set tb [file join $root sim/vivado $tb_name]
if {[llength [get_files -quiet $tb]] == 0} {
  add_files -fileset sim_1 -norecurse $tb
}
set_property top $tb_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

launch_simulation -simset sim_1 -scripts_only -absolute_path
puts "XSIM_BD_SCRIPTS_OK OUT=$out"

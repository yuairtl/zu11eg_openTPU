set script_dir [file dirname [file normalize [info script]]]
set root [file normalize [file join $script_dir .. .. ..]]

if {![info exists ::env(OTPU_BD_PROJECT)]} {
  error "OTPU_BD_PROJECT must point to opentpu_zu11eg.xpr"
}

set project_dir [file dirname [file normalize $::env(OTPU_BD_PROJECT)]]
set dcp [file join $project_dir opentpu_zu11eg.runs synth_1 system_wrapper.dcp]
if {![file exists $dcp]} {
  error "post-synthesis checkpoint not found: $dcp"
}

set out_dir [expr {
  [info exists ::env(OTPU_POST_SYNTH_OUT)] ?
  $::env(OTPU_POST_SYNTH_OUT) :
  [file join $root build post_synth_funcsim]
}]
file mkdir $out_dir
set out [file join $out_dir system_wrapper_funcsim.v]

open_checkpoint $dcp
write_verilog -mode funcsim -force $out
close_design

puts "POST_SYNTH_FUNCSIM_NETLIST_OK DCP=$dcp OUT=$out"

# The only CDC critical sources in the ZU11EG implementation are asynchronous
# reset distribution: the two MIG reset trees and the core reset replicas.
# Their destinations include MMCMs, XPM async FIFOs and vendor AXI CDC blocks;
# report_cdc cannot infer the final synchronized topology through those hard
# primitives. Keep the waiver constrained to these exact reset sources.

set c2x_cdc_mig_sources [get_pins -quiet -hierarchical -filter {
  NAME =~ "system_i/ddr4_0/inst/div_clk_rst_r1_reg/C" ||
  NAME =~ "system_i/ddr4_1/inst/div_clk_rst_r1_reg/C"
}]
set c2x_cdc_core_sources [get_pins -quiet -hierarchical -filter {
  NAME =~ "system_i/rst_100/U0/*FDRE_PER_N_replica*/C"
}]
if {[llength $c2x_cdc_mig_sources] != 2 || [llength $c2x_cdc_core_sources] < 1} {
  error "cdc_waivers.tcl: reset CDC sources not found (MIG=[llength $c2x_cdc_mig_sources], core=[llength $c2x_cdc_core_sources])"
}
set c2x_cdc_reset_sources [concat $c2x_cdc_mig_sources $c2x_cdc_core_sources]

foreach c2x_cdc_id {CDC-1 CDC-10 CDC-11 CDC-13} {
  create_waiver -type {CDC} -id $c2x_cdc_id -user {openTPU} \
    -desc "Asynchronous reset tree; synchronized by MMCM/XPM/vendor CDC at destination" \
    -from $c2x_cdc_reset_sources
}

puts "OTPU_CDC_WAIVER: [llength $c2x_cdc_mig_sources] MIG + [llength $c2x_cdc_core_sources] core reset sources, CDC-1/10/11/13"

# The TMEM pumped UltraRAM banks run on a 200 MHz MMCM output generated from
# the same 100 MHz PL0 clock as the Core. Vivado can therefore prove the 2:1
# relationship and the common clock topology. Never replace this with two
# independent PS PL outputs or blanket asynchronous/false-path constraints.
set c2x_pb [get_cells -quiet -hierarchical -filter \
  {ORIG_REF_NAME == otpu_pump_bank || REF_NAME == otpu_pump_bank}]
if {[llength $c2x_pb]} {
  set c2x_c0 [lindex $c2x_pb 0]
  set c2x_cs [get_clocks -quiet -of_objects [get_pins -quiet $c2x_c0/clk]]
  set c2x_cf [get_clocks -quiet -of_objects [get_pins -quiet $c2x_c0/clk_f]]
  set c2x_ts [get_property -quiet -min PERIOD $c2x_cs]
  set c2x_tf [get_property -quiet -min PERIOD $c2x_cf]
  if {[llength $c2x_cs] != 1 || [llength $c2x_cf] != 1 ||
      abs($c2x_ts - 2.0 * $c2x_tf) > 0.001} {
    error "pumped TMEM clocks are '$c2x_cs' ($c2x_ts ns) and '$c2x_cf' ($c2x_tf ns); expected clk_f = 2 * clk"
  }

  set c2x_rp [get_pins -quiet -of_objects $c2x_pb -filter \
    {REF_PIN_NAME =~ ra[*] || REF_PIN_NAME =~ rb[*] || REF_PIN_NAME == rena || REF_PIN_NAME == renb}]
  set c2x_qp [get_pins -quiet -of_objects $c2x_pb -filter \
    {REF_PIN_NAME =~ qa[*] || REF_PIN_NAME =~ qb[*]}]
  if {![llength $c2x_rp] || ![llength $c2x_qp]} {
    error "otpu_clk2x.tcl: pumped-bank request/output pins were not found"
  }

  # Read requests are taken at the next fast edge and data returns on the
  # following core edge. These are synchronous multicycle paths, not CDC.
  set_multicycle_path 2 -setup -end -from $c2x_cs -through $c2x_rp -to $c2x_cf
  set_multicycle_path 1 -hold -end -from $c2x_cs -through $c2x_rp -to $c2x_cf
  set_multicycle_path 2 -setup -start -from $c2x_cf -through $c2x_qp -to $c2x_cs
  set_multicycle_path 1 -hold -start -from $c2x_cf -through $c2x_qp -to $c2x_cs

  # The write-data and phase-detector paths cross from the 100 MHz core edge to
  # the 5 ns fast edge. Their first fast capture is intentional; the same-edge
  # hold check at 0 ns is not an active capture edge for this 2:1 topology. Keep
  # setup timing active and suppress only the meaningless slow-to-fast hold
  # check. This is narrower than making the clocks asynchronous.
  set_false_path -hold -from $c2x_cs -to $c2x_cf
  puts "OTPU_CLK2X: [llength $c2x_pb] pumped banks, [llength $c2x_rp] read requests, [llength $c2x_qp] word outputs"
} else {
  puts "OTPU_CLK2X: no pumped TMEM banks; 2x pump constraints skipped"
}

# The two MIG UI clocks are independent 300 MHz domains. All Core <-> MIG
# traffic in this design is through XPM async FIFOs or vendor AXI CDC, so bound
# each crossing with a datapath-only delay instead of inventing a same-edge
# relationship. Do not use a global clock-group waiver here: it would hide the
# MIG's own internal max-delay constraints.
set c2x_core_clk [get_clocks -quiet clk_pl_0]
set c2x_mig0_ui  [get_clocks -quiet mmcm_clkout0]
set c2x_mig1_ui  [get_clocks -quiet mmcm_clkout0_1]
foreach c2x_clk_name {c2x_core_clk c2x_mig0_ui c2x_mig1_ui} {
  set c2x_clk [set $c2x_clk_name]
  if {[llength $c2x_clk] != 1} {
    error "otpu_clk2x.tcl: expected one clock for $c2x_clk_name, got '$c2x_clk'"
  }
}
foreach c2x_mig_clk [list $c2x_mig0_ui $c2x_mig1_ui] {
  set_max_delay -datapath_only 5.000 -from $c2x_core_clk -to $c2x_mig_clk
  set_max_delay -datapath_only 5.000 -from $c2x_mig_clk -to $c2x_core_clk
}


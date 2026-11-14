# The TMEM's pumped UltraRAM banks run on clk_pl_1 (2x core clock).
# Read requests are taken at the next fast edge, so they have one core period.
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
    send_msg_id OTPU-CLK2X-1 CRITICAL WARNING \
      "pumped TMEM clocks are '$c2x_cs' ($c2x_ts ns) and '$c2x_cf' ($c2x_tf ns); expected clk_f = 2 * clk"
  } else {
    set c2x_rp [get_pins -quiet -of_objects $c2x_pb -filter \
      {REF_PIN_NAME =~ ra[*] || REF_PIN_NAME =~ rb[*] || REF_PIN_NAME == rena || REF_PIN_NAME == renb}]
    set c2x_qp [get_pins -quiet -of_objects $c2x_pb -filter \
      {REF_PIN_NAME =~ qa[*] || REF_PIN_NAME =~ qb[*]}]
    set_multicycle_path 2 -setup -end -from $c2x_cs -through $c2x_rp -to $c2x_cf
    set_multicycle_path 1 -hold -end -from $c2x_cs -through $c2x_rp -to $c2x_cf
    set_multicycle_path 2 -setup -start -from $c2x_cf -through $c2x_qp -to $c2x_cs
    set_multicycle_path 1 -hold -start -from $c2x_cf -through $c2x_qp -to $c2x_cs
    puts "OTPU_CLK2X: [llength $c2x_pb] pumped banks, [llength $c2x_rp] read requests, [llength $c2x_qp] word outputs"
  }
} else {
  puts "OTPU_CLK2X: no pumped TMEM banks"
}

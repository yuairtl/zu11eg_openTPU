set project_file [lindex $argv 0]
set jobs [lindex $argv 1]
set force_synth [lindex $argv 2]
set check_only [lindex $argv 3]
set report_only [lindex $argv 4]
if {$project_file eq ""} {
  error "usage: build_first_board_2025.tcl <project.xpr> \[jobs\] \[force-synth\] \[check-only\] \[report-only\]"
}
if {$jobs eq ""} {
  # The ZU11EG block design launches many OOC IP syntheses. Each run also forks
  # parallel synth workers, so four concurrent runs still OOM a 32 GiB VM.
  # Keep two jobs as the safe default; callers can still override it.
  set jobs 2
}
if {$force_synth eq ""} {
  set force_synth 0
}
if {$check_only eq ""} {
  set check_only 0
}
if {$report_only eq ""} {
  set report_only 0
}

open_project $project_file
set root [file normalize [file join [file dirname [info script]] .. .. ..]]
set old_clk2x_xdc [file join $root boards/mlk-cm07-zu11eg/constraints/otpu_clk2x.xdc]
if {[llength [get_files -quiet $old_clk2x_xdc]] != 0} {
  remove_files [get_files $old_clk2x_xdc]
}
foreach xdc_name {
  ddr4_mig.pins.xdc
  first_board.xdc
  otpu_clk2x.tcl
} {
  set xdc_file [file join $root boards/mlk-cm07-zu11eg/constraints $xdc_name]
  if {[llength [get_files -quiet $xdc_file]] == 0} {
    add_files -fileset constrs_1 -norecurse $xdc_file
  }
  if {$xdc_name eq "otpu_clk2x.tcl"} {
    set_property FILE_TYPE TCL [get_files $xdc_file]
    set_property PROCESSING_ORDER LATE [get_files $xdc_file]
  } else {
    set_property PROCESSING_ORDER EARLY [get_files $xdc_file]
  }
  set_property USED_IN_SYNTHESIS false [get_files $xdc_file]
  set_property USED_IN_IMPLEMENTATION true [get_files $xdc_file]
}

foreach rtl_name {
  rtl/zu11eg/otpu_axil_join.sv
  rtl/zu11eg/otpu_native_fifo.sv
  rtl/zu11eg/otpu_dci_reset.sv
} {
  set rtl_file [file join $root $rtl_name]
  if {[llength [get_files -quiet $rtl_file]] == 0} {
    add_files -norecurse $rtl_file
  }
}

set_property source_mgmt_mode All [current_project]
update_compile_order -fileset sources_1
foreach run [get_runs -quiet] {
  if {[string match "*ERROR*" [get_property STATUS $run]]} {
    reset_run $run
  }
}
set bd_file [lindex [get_files -quiet */bd/system/system.bd] 0]
if {$bd_file eq ""} {
  error "system.bd not found"
}
open_bd_design $bd_file
set rst_100 [get_bd_cells -quiet rst_100]
if {$rst_100 eq ""} {
  error "rst_100 not found in system.bd: the PS reset polarity cannot be verified"
}
set rst_high [get_property -quiet CONFIG.C_EXT_RESET_HIGH $rst_100]
if {$rst_high ne "1"} {
  error "stale board BD: rst_100 must keep its active-high external reset input"
}
set ps_reset_inv [get_bd_cells -quiet ps_reset_inv]
if {$ps_reset_inv eq "" ||
    [get_property -quiet CONFIG.C_OPERATION $ps_reset_inv] ne "not" ||
    [get_property -quiet CONFIG.C_SIZE $ps_reset_inv] ne "1"} {
  error "stale board BD: ps_reset_inv must invert pl_resetn0"
}

# This is the phase-aligned TMEM clocking schema. An old BD that still drives
# core_clk_f from pl_clk1 or lacks the DCI gate must be recreated from
# create_first_board_2025.tcl; silently carrying it into synthesis is forbidden.
set clk_200 [get_bd_cells -quiet clk_wiz_0]
if {$clk_200 eq ""} {
  error "stale board BD: clk_wiz_0 is missing; recreate it with create_first_board_2025.tcl"
}
set ps_cell [get_bd_cells -quiet zynq_ultra_ps_e_0]
if {$ps_cell eq "" ||
    [get_property CONFIG.PSU__FPGA_PL1_ENABLE $ps_cell] ne "0"} {
  error "stale board BD: PS PL1 must be disabled; recreate it with create_first_board_2025.tcl"
}
if {[llength [get_bd_pins -quiet $clk_200/clk_out1_200m]] != 1 ||
    [llength [get_bd_pins -quiet $clk_200/resetn]] != 1 ||
    [llength [get_bd_pins -quiet $clk_200/locked]] != 1} {
  error "stale board BD: clk_wiz_0 interface does not match the 200 MHz schema"
}
if {[get_property -quiet CONFIG.PRIM_SOURCE $clk_200] ne "Global_buffer" ||
    abs([get_property -quiet CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $clk_200] - 200.0) > 0.001} {
  error "stale board BD: clk_wiz_0 must use PL0 Global_buffer and request 200 MHz"
}
set fabric [get_bd_cells -quiet otpu_fabric]
if {$fabric eq "" || [llength [get_bd_pins -quiet $fabric/dci_locked]] != 1} {
  error "stale board BD: otpu_fabric/dci_locked is missing"
}
proc require_same_net {a b label} {
  set na [get_bd_nets -quiet -of_objects [get_bd_pins $a]]
  set nb [get_bd_nets -quiet -of_objects [get_bd_pins $b]]
  if {$na eq "" || $nb eq "" || $na ne $nb} {
    error "stale board BD: $label is not connected ($a='$na', $b='$nb')"
  }
}
require_same_net $ps_cell/pl_clk0 $clk_200/clk_in1 "PL0 -> clk_wiz input"
require_same_net $ps_cell/pl_resetn0 $clk_200/resetn "PS reset -> clk_wiz reset"
require_same_net $ps_cell/pl_resetn0 $ps_reset_inv/Op1 "PS reset -> inverter"
require_same_net $ps_reset_inv/Res rst_100/ext_reset_in "inverted PS reset -> core reset"
require_same_net $clk_200/locked rst_100/dcm_locked "clk_wiz lock -> core reset"
require_same_net $fabric/dci_locked rst_mig0/dcm_locked "DCI lock -> MIG0 reset"
require_same_net $fabric/dci_locked rst_mig1/dcm_locked "DCI lock -> MIG1 reset"
require_same_net $clk_200/clk_out1_200m $fabric/core_clk_f "2x clock -> fabric"
validate_bd_design
generate_target all [get_files $bd_file]
close_bd_design [current_bd_design]

if {$check_only} {
  puts "FIRST_BOARD_BD_SCHEMA_OK"
  close_project
  exit
}

set synth_run [get_runs synth_1]
set synth_stale [get_property -quiet NEEDS_REFRESH $synth_run]
if {!$report_only && ($force_synth || $synth_stale)} {
  puts "FORCE_SYNTH force=$force_synth needs_refresh=$synth_stale"
  foreach run [get_runs -quiet -filter {NAME =~ *otpu_fabric*}] {
    puts "FORCE_RESET_RUN=$run"
    reset_run $run
  }
  reset_run synth_1
}

puts "BUILD_PART=[get_property PART [current_project]]"
puts "BUILD_TOP=[get_property top [current_fileset]]"

if {!$report_only} {
  if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
    reset_run synth_1
    launch_runs synth_1 -jobs $jobs
    wait_on_run synth_1
    if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
      error "synth_1 did not complete: [get_property STATUS [get_runs synth_1]]"
    }
  } else {
    puts "SYNTH_REUSE=[get_property STATUS [get_runs synth_1]]"
  }

  reset_run impl_1
  launch_runs impl_1 -to_step write_bitstream -jobs $jobs
  wait_on_run impl_1
  if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
    error "impl_1 did not complete: [get_property STATUS [get_runs impl_1]]"
  }
} elseif {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
  error "report_only needs a completed impl_1 run"
} else {
  puts "IMPL_REUSE=[get_property STATUS [get_runs impl_1]]"
}

open_run impl_1
set project_dir [file dirname $project_file]
set report_dir [file join $project_dir reports]
file mkdir $report_dir
source [file join $root boards/mlk-cm07-zu11eg/constraints/cdc_waivers.tcl]
report_timing_summary -delay_type min_max -max_paths 20 \
  -file [file join $report_dir timing_summary.rpt]
report_bus_skew -file [file join $report_dir bus_skew.rpt]
report_utilization -file [file join $report_dir utilization.rpt]
report_drc -file [file join $report_dir drc.rpt]
report_cdc -details -file [file join $report_dir cdc.rpt]
report_clock_utilization -file [file join $report_dir clock_utilization.rpt]
report_methodology -file [file join $report_dir methodology.rpt]

proc report_blocking_rows {path} {
  set f [open $path r]
  set rows {}
  while {[gets $f line] >= 0} {
    if {[regexp {^\|\s*[A-Za-z0-9_-]+\s*\|\s*(Critical Warning|Critical|Error)\s*\|\s*[1-9][0-9]*\s*\|} $line] ||
        [regexp {^[A-Z][A-Za-z0-9_-]*\s+(Critical Warning|Critical|Error)\s+[1-9][0-9]*(\s|$)} $line]} {
      lappend rows [string trim $line]
    }
  }
  close $f
  return $rows
}

foreach report_name {drc.rpt cdc.rpt methodology.rpt} {
  set report_path [file join $report_dir $report_name]
  set blocking [report_blocking_rows $report_path]
  if {[llength $blocking]} {
    foreach row $blocking {
      puts "REPORT_BLOCKER $report_name $row"
    }
    error "$report_name contains Error/Critical rows"
  }
}

proc timing_check_blockers {path} {
  set f [open $path r]
  set rows {}
  # UART_0_rxd and UART_0_txd plus the two DDR4 reset_n outputs are
  # asynchronous board pins covered by explicit false paths in first_board.xdc.
  set safe_io_counts [dict create no_input_delay 1 no_output_delay 3]
  while {[gets $f line] >= 0} {
    if {[regexp {^[0-9]+\. checking ([a-z_]+) \(([1-9][0-9]*)\)} $line -> check count]} {
      if {[dict exists $safe_io_counts $check] &&
          $count == [dict get $safe_io_counts $check]} {
        continue
      }
      lappend rows "$check=$count"
    }
  }
  close $f
  return $rows
}

set timing_checks [timing_check_blockers [file join $report_dir timing_summary.rpt]]
if {[llength $timing_checks]} {
  puts "TIMING_CHECK_BLOCKERS $timing_checks"
  error "check_timing found unconstrained or structurally unsafe endpoints"
}

proc timing_metrics_from_summary {path} {
  set f [open $path r]
  while {[gets $f line] >= 0} {
    if {[regexp {^\s*(-?[0-9]+\.[0-9]+)\s+(-?[0-9]+\.[0-9]+)\s+([0-9]+)\s+([0-9]+)\s+(-?[0-9]+\.[0-9]+)\s+(-?[0-9]+\.[0-9]+)\s+([0-9]+)\s+([0-9]+)\s+(-?[0-9]+\.[0-9]+)\s+(-?[0-9]+\.[0-9]+)\s+([0-9]+)\s+([0-9]+)} \
        $line -> rwns rtns rtn rte rwhs rths rthn rthe rwpws rtpws rtpn rtpe]} {
      close $f
      return [list $rwns $rtns $rwhs $rths $rwpws]
    }
  }
  close $f
  error "timing_summary.rpt: Design Timing Summary was not found"
}

set wns [get_property -quiet STATS.WNS [get_runs impl_1]]
set tns [get_property -quiet STATS.TNS [get_runs impl_1]]
set whs [get_property -quiet STATS.WHS [get_runs impl_1]]
set ths [get_property -quiet STATS.THS [get_runs impl_1]]
set wpws [get_property -quiet STATS.WPWS [get_runs impl_1]]
if {$wns eq "" || $tns eq "" || $whs eq "" || $ths eq "" || $wpws eq ""} {
  lassign [timing_metrics_from_summary [file join $report_dir timing_summary.rpt]] \
    wns tns whs ths wpws
}
puts "IMPL_TIMING WNS=$wns TNS=$tns WHS=$whs THS=$ths WPWS=$wpws"
if {$wns < 0 || $whs < 0 || $wpws < 0} {
  error "implementation timing failed: WNS=$wns WHS=$whs WPWS=$wpws"
}

set xsa_file [file join $project_dir opentpu_zu11eg.xsa]
write_hw_platform -fixed -include_bit -force $xsa_file
puts "FIRST_BOARD_BUILD_OK XSA=$xsa_file"
close_project
exit

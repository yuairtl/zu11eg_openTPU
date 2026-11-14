set project_dir [lindex $argv 0]
if {$project_dir eq ""} {
    error "usage: create_first_board_2025.tcl <empty-project-dir>"
}
set here [file dirname [file normalize [info script]]]
set root [file normalize [file join $here .. .. ..]]
set part xczu11eg-ffvc1760-2-i

file mkdir $project_dir
create_project -force opentpu_zu11eg $project_dir/project -part $part
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property source_mgmt_mode All [current_project]

set rtl_files {
  rtl/vpu/otpu_fp.sv
  rtl/vpu/otpu_fpipe.sv
  rtl/top/otpu_pkg.sv
  rtl/mem/otpu_dram.sv
  rtl/mem/otpu_tmem.sv
  rtl/mem/otpu_native_dram.sv
  rtl/mem/otpu_actram.sv
  rtl/seq/otpu_seq.sv
  rtl/vpu/otpu_vtree.sv
  rtl/dma/otpu_dma.sv
  rtl/mxu/otpu_mxu.sv
  rtl/tech/generic/otpu_tech_dsp.sv
  rtl/tech/generic/otpu_tech_ram.sv
  rtl/vpu/otpu_quant.sv
  rtl/vpu/otpu_se_comp.sv
  rtl/vpu/otpu_se_tail.sv
  rtl/vpu/otpu_vpu.sv
  rtl/top/otpu_coll.sv
  rtl/exp/tmem_nocopy/otpu_tmem_model.sv
  rtl/top/otpu_slice_ila_ab.sv
  rtl/top/otpu_top.sv
  rtl/shell/otpu_board.sv
  rtl/shell/otpu_afifo.sv
  rtl/shell/otpu_mem_ch.sv
  rtl/shell/otpu_axi_split2.sv
  rtl/shell/otpu_ctrl.sv
  rtl/shell/otpu_trace.sv
  rtl/zu11eg/otpu_axil_join.sv
  rtl/zu11eg/otpu_native_fifo.sv
  rtl/zu11eg/otpu_native_axi_ch.sv
  rtl/zu11eg/otpu_native_axi_sys.sv
  rtl/zu11eg/otpu_dci_reset.sv
  rtl/boards/mlk-cm07-zu11eg/otpu_zu11eg_fabric.sv
  rtl/boards/mlk-cm07-zu11eg/otpu_zu11eg_fabric_v.v
}
add_files -norecurse [lmap f $rtl_files {file join $root $f}]
set_property include_dirs [list [file join $root rtl/top]] [current_fileset]
update_compile_order -fileset sources_1

create_bd_design system
current_bd_design system

set ddr_clk0 [create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ddr_clk0]
set_property -dict [list CONFIG.FREQ_HZ {100000000}] $ddr_clk0
set ddr_clk1 [create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ddr_clk1]
set_property -dict [list CONFIG.FREQ_HZ {100000000}] $ddr_clk1
set ddr0_port [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_rtl_0]
set ddr1_port [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_rtl_1]
set uart0_port [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART_0]

set ps [create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 zynq_ultra_ps_e_0]
# The reference MLK-CM07 ZU11EG PS console is UART0 on MIO34..35.
# Do not move it to MIO18..19: those pins are not the reference mapping.
set_property -dict [list \
  CONFIG.PSU__USE__M_AXI_GP0 {1} \
  CONFIG.PSU__USE__M_AXI_GP1 {0} \
  CONFIG.PSU__USE__M_AXI_GP2 {0} \
  CONFIG.PSU__MAXIGP0__DATA_WIDTH {128} \
  CONFIG.PSU__USE__S_AXI_GP2 {1} \
  CONFIG.PSU__SAXIGP2__DATA_WIDTH {128} \
  CONFIG.PSU__USE__S_AXI_GP3 {1} \
  CONFIG.PSU__SAXIGP3__DATA_WIDTH {128} \
  CONFIG.PSU__USE__IRQ0 {1} \
  CONFIG.PSU__USE__FABRIC__RST {1} \
  CONFIG.PSU__PSS_REF_CLK__FREQMHZ {33.333333} \
  CONFIG.PSU__FPGA_PL0_ENABLE {1} \
  CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100} \
  CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL {IOPLL} \
  CONFIG.PSU__FPGA_PL1_ENABLE {0} \
  CONFIG.PSU__DDRC__ENABLE {1} \
  CONFIG.PSU__DDRC__MEMORY_TYPE {DDR 4} \
  CONFIG.PSU__DDRC__DEVICE_CAPACITY {16384 MBits} \
  CONFIG.PSU__DDRC__DRAM_WIDTH {16 Bits} \
  CONFIG.PSU__DDRC__SPEED_BIN {DDR4_2400T} \
  CONFIG.PSU__DDRC__ROW_ADDR_COUNT {17} \
  CONFIG.PSU__DDRC__COL_ADDR_COUNT {10} \
  CONFIG.PSU__DDRC__BANK_ADDR_COUNT {2} \
  CONFIG.PSU__DDRC__BG_ADDR_COUNT {1} \
  CONFIG.PSU__DDRC__BUS_WIDTH {64 Bit} \
  CONFIG.PSU__DDRC__RANK_ADDR_COUNT {0} \
  CONFIG.PSU__DDRC__ECC {Disabled} \
  CONFIG.PSU__DDRC__DM_DBI {DM_NO_DBI} \
  CONFIG.PSU__CRF_APB__DDR_CTRL__FREQMHZ {1200} \
  CONFIG.PSU__SD1__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__SD1__PERIPHERAL__IO {MIO 39 .. 51} \
  CONFIG.PSU__SD1__SLOT_TYPE {eMMC} \
  CONFIG.PSU__SD1__DATA_TRANSFER_MODE {8Bit} \
  CONFIG.PSU__UART0__BAUD_RATE {115200} \
  CONFIG.PSU__UART0__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__UART0__PERIPHERAL__IO {MIO 34 .. 35} \
  CONFIG.PSU__UART0__MODEM__ENABLE {0} \
  CONFIG.PSU__QSPI__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__QSPI__PERIPHERAL__MODE {Dual Parallel} \
  CONFIG.PSU__QSPI__PERIPHERAL__IO {MIO 0 .. 12} \
  CONFIG.PSU__QSPI__GRP_FBCLK__ENABLE {1} \
  CONFIG.PSU__QSPI__GRP_FBCLK__IO {MIO 6} \
  CONFIG.PSU__ENET3__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__ENET3__PERIPHERAL__IO {MIO 64 .. 75} \
  CONFIG.PSU__ENET3__GRP_MDIO__ENABLE {1} \
  CONFIG.PSU__ENET3__GRP_MDIO__IO {MIO 76 .. 77} \
  CONFIG.PSU__ENET3__FIFO__ENABLE {0} \
  CONFIG.PSU__ENET3__PTP__ENABLE {0} \
  CONFIG.PSU__ENET3__TSU__ENABLE {0} \
  CONFIG.PSU__GEM3_COHERENCY {0} \
  CONFIG.PSU__GEM3_ROUTE_THROUGH_FPD {0} \
  CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__FREQMHZ {125} \
  CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__SRCSEL {IOPLL} \
] $ps

proc make_ddr {name} {
  set ddr [create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 $name]
  # Keep the PL MIG parameters aligned with the verified
  # E:/study/milianke/milian_zu11eg/pl_ddr_test board baseline.
  set_property -dict [list \
    CONFIG.C0.DDR4_AxiSelection {true} \
    CONFIG.C0.DDR4_AxiAddressWidth {32} \
    CONFIG.C0.DDR4_AxiDataWidth {512} \
    CONFIG.C0.DDR4_AxiIDWidth {4} \
    CONFIG.C0.DDR4_CasLatency {16} \
    CONFIG.C0.DDR4_CasWriteLatency {12} \
    CONFIG.C0.DDR4_DataWidth {64} \
    CONFIG.C0.DDR4_InputClockPeriod {9996} \
    CONFIG.C0.DDR4_MemoryPart {MT40A512M16HA-083E} \
    CONFIG.C0.DDR4_TimePeriod {833} \
  ] $ddr
  return $ddr
}
set ddr0 [make_ddr ddr4_0]
set ddr1 [make_ddr ddr4_1]

set fabric [create_bd_cell -type module -reference otpu_zu11eg_fabric_v otpu_fabric]

set h2c [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 h2c_cdma]
set_property -dict [list \
  CONFIG.C_ADDR_WIDTH {64} \
  CONFIG.C_M_AXI_DATA_WIDTH {128} \
  CONFIG.C_M_AXI_MAX_BURST_LEN {256} \
  CONFIG.C_INCLUDE_SG {0} \
] $h2c
set c2h [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 c2h_cdma]
set_property -dict [list \
  CONFIG.C_ADDR_WIDTH {64} \
  CONFIG.C_M_AXI_DATA_WIDTH {128} \
  CONFIG.C_M_AXI_MAX_BURST_LEN {256} \
  CONFIG.C_INCLUDE_SG {0} \
] $c2h

set uart [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0]
set_property -dict [list \
  CONFIG.C_BAUDRATE {115200} \
  CONFIG.C_DATA_BITS {8} \
  CONFIG.C_USE_PARITY {0} \
  CONFIG.C_S_AXI_ACLK_FREQ_HZ {99999992} \
] $uart

# The TMEM pump requires a phase-aligned 2x clock. Never derive that
# relationship from two independent PS PL clock outputs: generate 200 MHz
# from the same 100 MHz PL0 clock so Vivado and hardware share one topology.
set clk_200 [create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0]
set_property -dict [list \
  CONFIG.PRIMITIVE {MMCM} \
  CONFIG.PRIM_IN_FREQ {100.000} \
  CONFIG.PRIM_SOURCE {Global_buffer} \
  CONFIG.CLKIN1_JITTER_PS {100.0} \
  CONFIG.NUM_OUT_CLKS {1} \
  CONFIG.CLKOUT1_USED {true} \
  CONFIG.CLKOUT2_USED {false} \
  CONFIG.CLKOUT3_USED {false} \
  CONFIG.CLKOUT4_USED {false} \
  CONFIG.CLKOUT5_USED {false} \
  CONFIG.CLKOUT6_USED {false} \
  CONFIG.CLKOUT7_USED {false} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} \
  CONFIG.CLKOUT1_REQUESTED_PHASE {0.000} \
  CONFIG.CLK_OUT1_PORT {clk_out1_200m} \
  CONFIG.USE_LOCKED {true} \
  CONFIG.USE_RESET {true} \
  CONFIG.RESET_PORT {resetn} \
  CONFIG.RESET_TYPE {ACTIVE_LOW} \
] $clk_200

set intc [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 axi_intc_0]
set_property CONFIG.C_IRQ_CONNECTION {1} $intc
set irq_concat [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 irq_concat]
set_property -dict [list CONFIG.NUM_PORTS {3}] $irq_concat

set ctrl_ic [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ctrl_ic]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {5}] $ctrl_ic
set h2c_route [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 h2c_route]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {2}] $h2c_route
set c2h_route [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 c2h_route]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {2}] $c2h_route
set host_merge [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 host_merge]
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] $host_merge
set mig0_ic [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 mig0_ic]
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1} \
  CONFIG.S00_HAS_DATA_FIFO {2} CONFIG.S01_HAS_DATA_FIFO {2} \
  CONFIG.M00_HAS_DATA_FIFO {2}] $mig0_ic
set mig1_ic [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 mig1_ic]
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1} \
  CONFIG.S00_HAS_DATA_FIFO {2} CONFIG.S01_HAS_DATA_FIFO {2} \
  CONFIG.M00_HAS_DATA_FIFO {2}] $mig1_ic

set rst_100 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_100]
set rst_mig0 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_mig0]
set rst_mig1 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_mig1]
# proc_sys_reset's external-reset polarity is propagated/read-only in 2025.2.
# Keep the default active-high input and invert pl_resetn0 in the BD.
set ps_reset_inv [create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 ps_reset_inv]
set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1}] $ps_reset_inv
set const0 [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const0]
set_property CONFIG.CONST_VAL {0} $const0
set calib_concat [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 calib_concat]
set_property -dict [list CONFIG.NUM_PORTS {2}] $calib_concat

# MIG physical clocks and resets.
connect_bd_intf_net [get_bd_intf_ports ddr_clk0] [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
connect_bd_intf_net [get_bd_intf_ports ddr_clk1] [get_bd_intf_pins ddr4_1/C0_SYS_CLK]
connect_bd_intf_net [get_bd_intf_ports ddr4_rtl_0] [get_bd_intf_pins ddr4_0/C0_DDR4]
connect_bd_intf_net [get_bd_intf_ports ddr4_rtl_1] [get_bd_intf_pins ddr4_1/C0_DDR4]
connect_bd_net [get_bd_pins const0/dout] [get_bd_pins ddr4_0/sys_rst] [get_bd_pins ddr4_1/sys_rst]

connect_bd_net [get_bd_pins $ps/pl_clk0] \
  [get_bd_pins $fabric/core_clk] \
  [get_bd_pins $clk_200/clk_in1] \
  [get_bd_pins rst_100/slowest_sync_clk] \
  [get_bd_pins $h2c/s_axi_lite_aclk] [get_bd_pins $h2c/m_axi_aclk] \
  [get_bd_pins $c2h/s_axi_lite_aclk] [get_bd_pins $c2h/m_axi_aclk] \
  [get_bd_pins $uart/s_axi_aclk] [get_bd_pins $intc/s_axi_aclk] \
  [get_bd_pins $ps/maxihpm0_fpd_aclk] \
  [get_bd_pins $ps/saxihp0_fpd_aclk] [get_bd_pins $ps/saxihp1_fpd_aclk] \
  [get_bd_pins ctrl_ic/ACLK] [get_bd_pins ctrl_ic/S00_ACLK] \
  [get_bd_pins ctrl_ic/M00_ACLK] [get_bd_pins ctrl_ic/M01_ACLK] \
  [get_bd_pins ctrl_ic/M02_ACLK] [get_bd_pins ctrl_ic/M03_ACLK] [get_bd_pins ctrl_ic/M04_ACLK] \
  [get_bd_pins h2c_route/ACLK] [get_bd_pins h2c_route/S00_ACLK] \
  [get_bd_pins h2c_route/M00_ACLK] [get_bd_pins h2c_route/M01_ACLK] \
  [get_bd_pins c2h_route/ACLK] [get_bd_pins c2h_route/S00_ACLK] \
  [get_bd_pins c2h_route/M00_ACLK] [get_bd_pins c2h_route/M01_ACLK] \
  [get_bd_pins host_merge/ACLK] [get_bd_pins host_merge/S00_ACLK] \
  [get_bd_pins host_merge/S01_ACLK] [get_bd_pins host_merge/M00_ACLK] \
  [get_bd_pins mig0_ic/S01_ACLK] [get_bd_pins mig1_ic/S01_ACLK]
connect_bd_net [get_bd_pins $clk_200/clk_out1_200m] [get_bd_pins $fabric/core_clk_f]

connect_bd_net [get_bd_pins $ps/pl_resetn0] [get_bd_pins $clk_200/resetn] \
  [get_bd_pins $ps_reset_inv/Op1]
connect_bd_net [get_bd_pins $ps_reset_inv/Res] [get_bd_pins rst_100/ext_reset_in]
connect_bd_net [get_bd_pins $clk_200/locked] [get_bd_pins rst_100/dcm_locked]
connect_bd_net [get_bd_pins rst_100/peripheral_aresetn] \
  [get_bd_pins $fabric/core_rstn] \
  [get_bd_pins $h2c/s_axi_lite_aresetn] \
  [get_bd_pins $c2h/s_axi_lite_aresetn] \
  [get_bd_pins $uart/s_axi_aresetn] [get_bd_pins $intc/s_axi_aresetn] \
  [get_bd_pins ctrl_ic/ARESETN] [get_bd_pins ctrl_ic/S00_ARESETN] \
  [get_bd_pins ctrl_ic/M00_ARESETN] [get_bd_pins ctrl_ic/M01_ARESETN] \
  [get_bd_pins ctrl_ic/M02_ARESETN] [get_bd_pins ctrl_ic/M03_ARESETN] \
  [get_bd_pins ctrl_ic/M04_ARESETN] \
  [get_bd_pins h2c_route/ARESETN] [get_bd_pins h2c_route/S00_ARESETN] \
  [get_bd_pins h2c_route/M00_ARESETN] [get_bd_pins h2c_route/M01_ARESETN] \
  [get_bd_pins c2h_route/ARESETN] [get_bd_pins c2h_route/S00_ARESETN] \
  [get_bd_pins c2h_route/M00_ARESETN] [get_bd_pins c2h_route/M01_ARESETN] \
  [get_bd_pins host_merge/ARESETN] [get_bd_pins host_merge/S00_ARESETN] \
  [get_bd_pins host_merge/S01_ARESETN] [get_bd_pins host_merge/M00_ARESETN] \
  [get_bd_pins mig0_ic/S01_ARESETN] [get_bd_pins mig1_ic/S01_ARESETN]

# DDR MIG AXI clocks/resets and shared AXI paths.
connect_bd_net [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst] [get_bd_pins rst_mig0/ext_reset_in]
connect_bd_net [get_bd_pins ddr4_1/c0_ddr4_ui_clk_sync_rst] [get_bd_pins rst_mig1/ext_reset_in]
connect_bd_net [get_bd_pins $fabric/dci_locked] \
  [get_bd_pins rst_mig0/dcm_locked] [get_bd_pins rst_mig1/dcm_locked]
connect_bd_net [get_bd_pins ddr4_0/c0_ddr4_ui_clk] \
  [get_bd_pins $fabric/mig0_clk] [get_bd_pins rst_mig0/slowest_sync_clk] \
  [get_bd_pins mig0_ic/ACLK] [get_bd_pins mig0_ic/S00_ACLK] [get_bd_pins mig0_ic/M00_ACLK]
connect_bd_net [get_bd_pins ddr4_1/c0_ddr4_ui_clk] \
  [get_bd_pins $fabric/mig1_clk] [get_bd_pins rst_mig1/slowest_sync_clk] \
  [get_bd_pins mig1_ic/ACLK] [get_bd_pins mig1_ic/S00_ACLK] [get_bd_pins mig1_ic/M00_ACLK]
connect_bd_net [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst] [get_bd_pins $fabric/mig0_rst]
connect_bd_net [get_bd_pins ddr4_1/c0_ddr4_ui_clk_sync_rst] [get_bd_pins $fabric/mig1_rst]
connect_bd_net [get_bd_pins rst_mig0/peripheral_aresetn] \
  [get_bd_pins ddr4_0/c0_ddr4_aresetn] \
  [get_bd_pins mig0_ic/ARESETN] [get_bd_pins mig0_ic/S00_ARESETN] [get_bd_pins mig0_ic/M00_ARESETN]
connect_bd_net [get_bd_pins rst_mig1/peripheral_aresetn] \
  [get_bd_pins ddr4_1/c0_ddr4_aresetn] \
  [get_bd_pins mig1_ic/ARESETN] [get_bd_pins mig1_ic/S00_ARESETN] [get_bd_pins mig1_ic/M00_ARESETN]

connect_bd_net [get_bd_pins ddr4_0/c0_init_calib_complete] [get_bd_pins calib_concat/In0]
connect_bd_net [get_bd_pins ddr4_1/c0_init_calib_complete] [get_bd_pins calib_concat/In1]
connect_bd_net [get_bd_pins calib_concat/dout] [get_bd_pins $fabric/calib]

# Control plane.
connect_bd_intf_net [get_bd_intf_pins $ps/M_AXI_HPM0_FPD] [get_bd_intf_pins ctrl_ic/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins ctrl_ic/M00_AXI] [get_bd_intf_pins $fabric/S_AXI_CTRL]
connect_bd_intf_net [get_bd_intf_pins ctrl_ic/M01_AXI] [get_bd_intf_pins $h2c/S_AXI_LITE]
connect_bd_intf_net [get_bd_intf_pins ctrl_ic/M02_AXI] [get_bd_intf_pins $c2h/S_AXI_LITE]
connect_bd_intf_net [get_bd_intf_pins ctrl_ic/M03_AXI] [get_bd_intf_pins $uart/S_AXI]
connect_bd_intf_net [get_bd_intf_pins ctrl_ic/M04_AXI] [get_bd_intf_pins $intc/S_AXI]
connect_bd_intf_net [get_bd_intf_ports UART_0] [get_bd_intf_pins $uart/UART]

# H2C and C2H route between PS DDR and the PL host aperture.
connect_bd_intf_net [get_bd_intf_pins $h2c/M_AXI] [get_bd_intf_pins h2c_route/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins h2c_route/M00_AXI] [get_bd_intf_pins $ps/S_AXI_HP0_FPD]
connect_bd_intf_net [get_bd_intf_pins h2c_route/M01_AXI] [get_bd_intf_pins host_merge/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins $c2h/M_AXI] [get_bd_intf_pins c2h_route/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins c2h_route/M00_AXI] [get_bd_intf_pins $ps/S_AXI_HP1_FPD]
connect_bd_intf_net [get_bd_intf_pins c2h_route/M01_AXI] [get_bd_intf_pins host_merge/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins host_merge/M00_AXI] [get_bd_intf_pins $fabric/S_AXI_HOST]

# Per-MIG memory fabric: 512-bit core master and 128-bit host window master.
connect_bd_intf_net [get_bd_intf_pins $fabric/M_AXI_CORE0] [get_bd_intf_pins mig0_ic/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins $fabric/M_AXI_HOST0] [get_bd_intf_pins mig0_ic/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins mig0_ic/M00_AXI] [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
connect_bd_intf_net [get_bd_intf_pins $fabric/M_AXI_CORE1] [get_bd_intf_pins mig1_ic/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins $fabric/M_AXI_HOST1] [get_bd_intf_pins mig1_ic/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins mig1_ic/M00_AXI] [get_bd_intf_pins ddr4_1/C0_DDR4_S_AXI]

# Interrupt aggregation.
connect_bd_net [get_bd_pins $h2c/cdma_introut] [get_bd_pins irq_concat/In0]
connect_bd_net [get_bd_pins $c2h/cdma_introut] [get_bd_pins irq_concat/In1]
connect_bd_net [get_bd_pins $uart/interrupt] [get_bd_pins irq_concat/In2]
connect_bd_net [get_bd_pins irq_concat/dout] [get_bd_pins $intc/intr]
connect_bd_net [get_bd_pins $intc/irq] [get_bd_pins $ps/pl_ps_irq0]

# Address maps.
save_bd_design
foreach seg [get_bd_addr_segs -quiet] {
  set seg_name [get_property NAME $seg]
  if {[string match "*otpu_fabric*" $seg_name] ||
      [string match "*h2c_cdma*" $seg_name] ||
      [string match "*c2h_cdma*" $seg_name] ||
      [string match "*axi_uartlite_0*" $seg_name] ||
      [string match "*axi_intc_0*" $seg_name] ||
      [string match "*ddr4_*" $seg_name]} {
    puts "BD_ADDR_SEG $seg_name"
  }
}

assign_bd_address -offset 0xA0000000 -range 0x00010000 \
  -target_address_space [get_bd_addr_spaces $ps/Data] \
  [get_bd_addr_segs $fabric/S_AXI_CTRL/reg0] -force
assign_bd_address -offset 0xA0010000 -range 0x00010000 \
  -target_address_space [get_bd_addr_spaces $ps/Data] \
  [get_bd_addr_segs $h2c/S_AXI_LITE/Reg] -force
assign_bd_address -offset 0xA0020000 -range 0x00010000 \
  -target_address_space [get_bd_addr_spaces $ps/Data] \
  [get_bd_addr_segs $c2h/S_AXI_LITE/Reg] -force
assign_bd_address -offset 0xA0030000 -range 0x00010000 \
  -target_address_space [get_bd_addr_spaces $ps/Data] \
  [get_bd_addr_segs $uart/S_AXI/Reg] -force
assign_bd_address -offset 0xA0040000 -range 0x00010000 \
  -target_address_space [get_bd_addr_spaces $ps/Data] \
  [get_bd_addr_segs $intc/S_AXI/Reg] -force

foreach pair [list [list $h2c $ps/SAXIGP2/HP0_DDR_LOW] [list $c2h $ps/SAXIGP3/HP1_DDR_LOW]] {
    lassign $pair master_cell ddr_seg
    assign_bd_address -offset 0x00000000 -range 0x80000000 \
      -target_address_space [get_bd_addr_spaces $master_cell/Data] \
      [get_bd_addr_segs $ddr_seg] -force
    assign_bd_address -offset 0x0000000800000000 -range 0x0000000100000000 \
      -target_address_space [get_bd_addr_spaces $master_cell/Data] \
      [get_bd_addr_segs $fabric/S_AXI_HOST/reg0] -force
}

# Each physical channel starts at zero in its own master address space.
foreach master [list $fabric/M_AXI_CORE0 $fabric/M_AXI_HOST0] {
    assign_bd_address -offset 0x00000000 -range 0x100000000 \
      -target_address_space [get_bd_addr_spaces $master] \
      [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
}
foreach master [list $fabric/M_AXI_CORE1 $fabric/M_AXI_HOST1] {
    assign_bd_address -offset 0x00000000 -range 0x100000000 \
      -target_address_space [get_bd_addr_spaces $master] \
      [get_bd_addr_segs ddr4_1/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
}

validate_bd_design
save_bd_design

set bd_file [get_files system.bd]
make_wrapper -files $bd_file -top -import
set wrapper [get_files -quiet */system_wrapper.v]
if {$wrapper eq ""} {
    error "system_wrapper was not generated"
}
set_property top system_wrapper [current_fileset]
update_compile_order -fileset sources_1
set_property STEPS.OPT_DESIGN.TCL.PRE \
  [file join $root boards/mlk-cm07-zu11eg/vivado/insert_otpu_ila.tcl] \
  [get_runs impl_1]

set ddr_pins_xdc [file join $root boards/mlk-cm07-zu11eg/constraints/ddr4_mig.pins.xdc]
set first_board_xdc [file join $root boards/mlk-cm07-zu11eg/constraints/first_board.xdc]
set clk2x_tcl [file join $root boards/mlk-cm07-zu11eg/constraints/otpu_clk2x.tcl]
add_files -fileset constrs_1 -norecurse [list $ddr_pins_xdc $first_board_xdc $clk2x_tcl]
foreach xdc [list $ddr_pins_xdc $first_board_xdc] {
  set_property PROCESSING_ORDER EARLY [get_files $xdc]
  set_property USED_IN_SYNTHESIS false [get_files $xdc]
  set_property USED_IN_IMPLEMENTATION true [get_files $xdc]
}
set_property PROCESSING_ORDER LATE [get_files $clk2x_tcl]
set_property USED_IN_SYNTHESIS false [get_files $clk2x_tcl]
set_property USED_IN_IMPLEMENTATION true [get_files $clk2x_tcl]

generate_target all [get_files system.bd]
puts "QSPI_CFG=[get_property CONFIG.PSU__QSPI__PERIPHERAL__IO $ps] mode=[get_property CONFIG.PSU__QSPI__PERIPHERAL__MODE $ps] data=[get_property CONFIG.PSU__QSPI__PERIPHERAL__DATA_MODE $ps]"
puts "EMMC_CFG=[get_property CONFIG.PSU__SD1__PERIPHERAL__IO $ps] slot=[get_property CONFIG.PSU__SD1__SLOT_TYPE $ps] width=[get_property CONFIG.PSU__SD1__DATA_TRANSFER_MODE $ps]"
puts "FIRST_BOARD_BD_OK"
close_project
exit

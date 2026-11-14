`timescale 1ps / 1ps

import axi_vip_pkg::*;

module axi_mem_512 #(
  parameter int IDW = 2,
  parameter int AW = 33,
  parameter int BEATS = 2048
) (
  input  logic             clk,
  input  logic             rst,
  input  logic             awvalid,
  output logic             awready,
  input  logic [IDW-1:0]   awid,
  input  logic [AW-1:0]    awaddr,
  input  logic [7:0]       awlen,
  input  logic [2:0]       awsize,
  input  logic [1:0]       awburst,
  input  logic [511:0]     wdata,
  input  logic [63:0]      wstrb,
  input  logic             wlast,
  input  logic             wvalid,
  output logic             wready,
  output logic [IDW-1:0]   bid,
  output logic [1:0]       bresp,
  output logic             bvalid,
  input  logic             bready,
  input  logic             arvalid,
  output logic             arready,
  input  logic [IDW-1:0]   arid,
  input  logic [AW-1:0]    araddr,
  input  logic [7:0]       arlen,
  input  logic [2:0]       arsize,
  input  logic [1:0]       arburst,
  output logic [IDW-1:0]   rid,
  output logic [511:0]     rdata,
  output logic [1:0]       rresp,
  output logic             rlast,
  output logic             rvalid,
  input  logic             rready
);
  logic [511:0] mem [BEATS];
  logic [IDW-1:0] awid_q, arid_q;
  logic [AW-1:0] awaddr_q, araddr_q;
  logic [7:0] awlen_q, arlen_q, wbeat, rbeat;
  logic aw_active, ar_active;
  logic bvalid_q, rvalid_q;
  logic [2:0] bdelay, rdelay;
  logic [31:0] lfsr;

  assign awready = !rst && !aw_active && !bvalid_q && ((lfsr & 'h7) != 0);
  assign wready = !rst && aw_active && ((lfsr & 'h70) != 0);
  assign bvalid = bvalid_q;
  assign bid = awid_q;
  assign bresp = 2'b00;

  assign arready = !rst && !ar_active && !rvalid_q && ((lfsr & 'h700) != 0);
  assign rvalid = rvalid_q;
  assign rid = arid_q;
  assign rdata = mem[araddr_q[AW-1:6] + rbeat];
  assign rresp = 2'b00;
  assign rlast = rvalid_q && (rbeat == arlen_q);

  function automatic logic [511:0] merge_mask(
    input logic [511:0] old_d,
    input logic [511:0] new_d,
    input logic [63:0] mask
  );
    logic [511:0] value;
    value = old_d;
    for (int b = 0; b < 64; b++)
      if (mask[b])
        value[8*b +: 8] = new_d[8*b +: 8];
    return value;
  endfunction

  initial begin
    lfsr = 32'h51a2_c3d4;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      awid_q <= '0;
      arid_q <= '0;
      awaddr_q <= '0;
      araddr_q <= '0;
      awlen_q <= '0;
      arlen_q <= '0;
      wbeat <= '0;
      rbeat <= '0;
      aw_active <= 1'b0;
      ar_active <= 1'b0;
      bvalid_q <= 1'b0;
      rvalid_q <= 1'b0;
      bdelay <= '0;
      rdelay <= '0;
    end else begin
      lfsr <= lfsr * 32'h1665_2d5b + 32'h9e37_79b9;

      if (awvalid && awready) begin
        awid_q <= awid;
        awaddr_q <= awaddr;
        awlen_q <= awlen;
        wbeat <= '0;
        aw_active <= 1'b1;
        if (awsize != 3'd6 || awburst != 2'b01)
          $fatal(1, "axi_mem_512: unexpected write attributes size=%0d burst=%0d",
                 awsize, awburst);
      end

      if (wvalid && wready) begin
        automatic int unsigned idx = awaddr_q[AW-1:6] + wbeat;
        mem[idx] <= merge_mask(mem[idx], wdata, wstrb);
        if (wlast || wbeat == awlen_q) begin
          aw_active <= 1'b0;
          bdelay <= 3;
        end else begin
          wbeat <= wbeat + 1'b1;
        end
      end

      if (bdelay != 0) begin
        bdelay <= bdelay - 1'b1;
        if (bdelay == 1)
          bvalid_q <= 1'b1;
      end
      if (bvalid_q && bready)
        bvalid_q <= 1'b0;

      if (arvalid && arready) begin
        arid_q <= arid;
        araddr_q <= araddr;
        arlen_q <= arlen;
        rbeat <= '0;
        ar_active <= 1'b1;
        rdelay <= 2;
        if (arsize != 3'd6 || arburst != 2'b01)
          $fatal(1, "axi_mem_512: unexpected read attributes size=%0d burst=%0d",
                 arsize, arburst);
      end

      if (rdelay != 0) begin
        rdelay <= rdelay - 1'b1;
        if (rdelay == 1)
          rvalid_q <= 1'b1;
      end
      if (rvalid_q && rready) begin
        if (rbeat == arlen_q) begin
          rvalid_q <= 1'b0;
          ar_active <= 1'b0;
        end else begin
          rbeat <= rbeat + 1'b1;
        end
      end
    end
  end
endmodule

module ps_ddr_axi_128 #(
  parameter int AW = 64,
  parameter int BEATS = 4096
) (
  input  logic         clk,
  input  logic         rst,
  input  logic         w_awvalid,
  output logic         w_awready,
  input  logic [AW-1:0] w_awaddr,
  input  logic [7:0]   w_awlen,
  input  logic [2:0]   w_awsize,
  input  logic [1:0]   w_awburst,
  input  logic [127:0] w_wdata,
  input  logic [15:0]  w_wstrb,
  input  logic         w_wlast,
  input  logic         w_wvalid,
  output logic         w_wready,
  output logic [1:0]   w_bresp,
  output logic         w_bvalid,
  input  logic         w_bready,
  input  logic         r_arvalid,
  output logic         r_arready,
  input  logic [AW-1:0] r_araddr,
  input  logic [7:0]   r_arlen,
  input  logic [2:0]   r_arsize,
  input  logic [1:0]   r_arburst,
  output logic [127:0] r_rdata,
  output logic [1:0]   r_rresp,
  output logic         r_rlast,
  output logic         r_rvalid,
  input  logic         r_rready
);
  // Behavioral PS DDR behind the two PS HP ports. It checks traffic and data ordering, but it
  // does not model Zynq coherency, PS cache maintenance, or the internal PS DDR controller.
  logic [127:0] mem [BEATS];
  logic [AW-1:0] awaddr_q, araddr_q;
  logic [7:0] awlen_q, arlen_q, wbeat, rbeat;
  logic aw_active, ar_active, bvalid_q, rvalid_q;
  logic [2:0] bdelay, rdelay;

  assign w_awready = !rst && !aw_active && !bvalid_q;
  assign w_wready = !rst && aw_active;
  assign w_bvalid = bvalid_q;
  assign w_bresp = 2'b00;

  assign r_arready = !rst && !ar_active && !rvalid_q;
  assign r_rvalid = rvalid_q;
  assign r_rdata = mem[araddr_q[AW-1:4] + rbeat];
  assign r_rresp = 2'b00;
  assign r_rlast = rvalid_q && (rbeat == arlen_q);

  function automatic logic [127:0] merge_mask(
    input logic [127:0] old_d,
    input logic [127:0] new_d,
    input logic [15:0] mask
  );
    logic [127:0] value;
    value = old_d;
    for (int b = 0; b < 16; b++)
      if (mask[b])
        value[8*b +: 8] = new_d[8*b +: 8];
    return value;
  endfunction

  always_ff @(posedge clk) begin
    if (rst) begin
      awaddr_q <= '0;
      araddr_q <= '0;
      awlen_q <= '0;
      arlen_q <= '0;
      wbeat <= '0;
      rbeat <= '0;
      aw_active <= 1'b0;
      ar_active <= 1'b0;
      bvalid_q <= 1'b0;
      rvalid_q <= 1'b0;
      bdelay <= '0;
      rdelay <= '0;
    end else begin
      if (w_awvalid && w_awready) begin
        awaddr_q <= w_awaddr;
        awlen_q <= w_awlen;
        wbeat <= '0;
        aw_active <= 1'b1;
        if (w_awsize != 3'd4 || w_awburst != 2'b01)
          $fatal(1, "ps_ddr_axi_128: write attributes size=%0d burst=%0d",
                 w_awsize, w_awburst);
      end

      if (w_wvalid && w_wready) begin
        automatic int unsigned idx = awaddr_q[AW-1:4] + wbeat;
        mem[idx] <= merge_mask(mem[idx], w_wdata, w_wstrb);
        if (w_wlast || wbeat == awlen_q) begin
          aw_active <= 1'b0;
          bdelay <= 3;
        end else begin
          wbeat <= wbeat + 1'b1;
        end
      end

      if (bdelay != 0) begin
        bdelay <= bdelay - 1'b1;
        if (bdelay == 1)
          bvalid_q <= 1'b1;
      end
      if (bvalid_q && w_bready)
        bvalid_q <= 1'b0;

      if (r_arvalid && r_arready) begin
        araddr_q <= r_araddr;
        arlen_q <= r_arlen;
        rbeat <= '0;
        ar_active <= 1'b1;
        rdelay <= 2;
        if (r_arsize != 3'd4 || r_arburst != 2'b01)
          $fatal(1, "ps_ddr_axi_128: read attributes size=%0d burst=%0d",
                 r_arsize, r_arburst);
      end

      if (rdelay != 0) begin
        rdelay <= rdelay - 1'b1;
        if (rdelay == 1)
          rvalid_q <= 1'b1;
      end
      if (rvalid_q && r_rready) begin
        if (rbeat == arlen_q) begin
          rvalid_q <= 1'b0;
          ar_active <= 1'b0;
        end else begin
          rbeat <= rbeat + 1'b1;
        end
      end
    end
  end
endmodule

module tb_bd_cdma_roundtrip;
  localparam logic [63:0] PL_BASE = 64'h0000_0008_0000_0000;
  localparam logic [63:0] PL_DST  = 64'h0000_0008_0001_0000;
  localparam logic [63:0] PL_CORE = 64'h0000_0008_0000_8000;
  localparam logic [63:0] PS_BASE = 64'h0000_0000_0000_0000;
  localparam int BYTES = 4096;
  localparam int STRESS_BYTES = 512;
  localparam int STRESS_ITERS = 64;

  localparam logic [39:0] H2C_CTRL = 40'h00_A001_0000;
  localparam logic [39:0] C2H_CTRL = 40'h00_A002_0000;
  localparam logic [39:0] CDMACR   = 40'h00;
  localparam logic [39:0] CDMASR   = 40'h04;
  localparam logic [39:0] SA       = 40'h18;
  localparam logic [39:0] SA_HI    = 40'h1C;
  localparam logic [39:0] DA       = 40'h20;
  localparam logic [39:0] DA_HI    = 40'h24;
  localparam logic [39:0] BTT      = 40'h28;

  logic UART_0_rxd;
  logic UART_0_txd;
  logic ddr_clk0_clk_p, ddr_clk0_clk_n;
  logic ddr_clk1_clk_p, ddr_clk1_clk_n;

  wire ddr4_rtl_0_act_n;
  wire [16:0] ddr4_rtl_0_adr;
  wire [1:0] ddr4_rtl_0_ba;
  wire [0:0] ddr4_rtl_0_bg;
  wire [0:0] ddr4_rtl_0_ck_c;
  wire [0:0] ddr4_rtl_0_ck_t;
  wire [0:0] ddr4_rtl_0_cke;
  wire [0:0] ddr4_rtl_0_cs_n;
  wire [7:0] ddr4_rtl_0_dm_n;
  wire [63:0] ddr4_rtl_0_dq;
  wire [7:0] ddr4_rtl_0_dqs_c;
  wire [7:0] ddr4_rtl_0_dqs_t;
  wire [0:0] ddr4_rtl_0_odt;
  wire ddr4_rtl_0_reset_n;

  wire ddr4_rtl_1_act_n;
  wire [16:0] ddr4_rtl_1_adr;
  wire [1:0] ddr4_rtl_1_ba;
  wire [0:0] ddr4_rtl_1_bg;
  wire [0:0] ddr4_rtl_1_ck_c;
  wire [0:0] ddr4_rtl_1_ck_t;
  wire [0:0] ddr4_rtl_1_cke;
  wire [0:0] ddr4_rtl_1_cs_n;
  wire [7:0] ddr4_rtl_1_dm_n;
  wire [63:0] ddr4_rtl_1_dq;
  wire [7:0] ddr4_rtl_1_dqs_c;
  wire [7:0] ddr4_rtl_1_dqs_t;
  wire [0:0] ddr4_rtl_1_odt;
  wire ddr4_rtl_1_reset_n;

  always #4998 ddr_clk0_clk_p = ~ddr_clk0_clk_p;
  always #4998 ddr_clk1_clk_p = ~ddr_clk1_clk_p;
  assign ddr_clk0_clk_n = ~ddr_clk0_clk_p;
  assign ddr_clk1_clk_n = ~ddr_clk1_clk_p;

  system_wrapper dut (.*);

  wire ps_clk = dut.system_i.zynq_ultra_ps_e_0_pl_clk0;

  logic [15:0] ps_awid, ps_bid;
  logic [39:0] ps_awaddr, ps_araddr;
  logic [7:0] ps_awlen, ps_arlen;
  logic [2:0] ps_awsize, ps_arsize;
  logic [1:0] ps_awburst, ps_arburst;
  logic ps_awvalid, ps_awready, ps_wvalid, ps_wready;
  logic [127:0] ps_wdata, ps_rdata;
  logic [15:0] ps_wstrb;
  logic ps_wlast, ps_bvalid, ps_bready;
  logic [1:0] ps_bresp;
  logic [15:0] ps_arid, ps_rid;
  logic ps_arvalid, ps_arready, ps_rvalid, ps_rready, ps_rlast;
  logic [1:0] ps_rresp;

  logic [511:0] expected_beat;
  logic [511:0] core_read_mem [64];
  int c2h_ps_wbeats = 0;
  int h2c_ps_rbeats = 0;
  int core_read_count = 0;
  int core_cmd_handshakes = 0;
  int pattern_iter = 0;
  logic core_read_capture = 1'b0;

  logic [1:0] core_n_cvalid, core_n_cready, core_n_cwe;
  logic [1:0] core_n_wvalid, core_n_wready, core_n_rvalid;
  logic [1:0][24:0] core_n_caddr;
  logic [1:0][511:0] core_n_wdata, core_n_rdata;
  logic [1:0][63:0] core_n_wmask;
  logic [1:0][15:0] core_n_wdone;
  logic [1:0] core_n_err;

  logic test_core_awid, test_core_awvalid;
  logic [31:0] test_core_awaddr;
  logic [7:0] test_core_awlen;
  logic [2:0] test_core_awsize;
  logic [1:0] test_core_awburst;
  logic test_core_awlock;
  logic [3:0] test_core_awcache;
  logic [2:0] test_core_awprot;
  logic [3:0] test_core_awqos;
  logic [511:0] test_core_wdata;
  logic [63:0] test_core_wstrb;
  logic test_core_wlast, test_core_wvalid;
  logic test_core_bready;
  logic test_core_arid, test_core_arvalid;
  logic [31:0] test_core_araddr;
  logic [7:0] test_core_arlen;
  logic [2:0] test_core_arsize;
  logic [1:0] test_core_arburst;
  logic test_core_arlock;
  logic [3:0] test_core_arcache;
  logic [2:0] test_core_arprot;
  logic [3:0] test_core_arqos;
  logic test_core_rready;

  logic hp1_awready, hp1_wready, hp1_bvalid, hp0_arready;
  logic hp0_rvalid, hp0_rlast;
  logic [1:0] hp1_bresp, hp0_rresp;
  logic [127:0] hp0_rdata;
  logic peripheral_rstn;

  ps_ddr_axi_128 ps_mem (
    .clk(ps_clk), .rst(~peripheral_rstn),
    .w_awvalid(dut.system_i.c2h_route_M00_AXI_AWVALID),
    .w_awready(hp1_awready),
    .w_awaddr(dut.system_i.c2h_route_M00_AXI_AWADDR),
    .w_awlen(dut.system_i.c2h_route_M00_AXI_AWLEN),
    .w_awsize(dut.system_i.c2h_route_M00_AXI_AWSIZE),
    .w_awburst(dut.system_i.c2h_route_M00_AXI_AWBURST),
    .w_wdata(dut.system_i.c2h_route_M00_AXI_WDATA),
    .w_wstrb(dut.system_i.c2h_route_M00_AXI_WSTRB),
    .w_wlast(dut.system_i.c2h_route_M00_AXI_WLAST),
    .w_wvalid(dut.system_i.c2h_route_M00_AXI_WVALID),
    .w_wready(hp1_wready),
    .w_bresp(hp1_bresp), .w_bvalid(hp1_bvalid),
    .w_bready(dut.system_i.c2h_route_M00_AXI_BREADY),
    .r_arvalid(dut.system_i.h2c_route_M00_AXI_ARVALID),
    .r_arready(hp0_arready),
    .r_araddr(dut.system_i.h2c_route_M00_AXI_ARADDR),
    .r_arlen(dut.system_i.h2c_route_M00_AXI_ARLEN),
    .r_arsize(dut.system_i.h2c_route_M00_AXI_ARSIZE),
    .r_arburst(dut.system_i.h2c_route_M00_AXI_ARBURST),
    .r_rdata(hp0_rdata), .r_rresp(hp0_rresp), .r_rlast(hp0_rlast),
    .r_rvalid(hp0_rvalid),
    .r_rready(dut.system_i.h2c_route_M00_AXI_RREADY)
  );

  assign ps_awready = dut.system_i.zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWREADY;
  assign ps_wready = dut.system_i.zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WREADY;
  assign ps_bid = dut.system_i.zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BID;
  assign ps_bresp = dut.system_i.zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BRESP;
  assign ps_bvalid = dut.system_i.zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BVALID;
  assign ps_arready = dut.system_i.zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARREADY;
  assign ps_rid = dut.system_i.zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RID;
  assign ps_rdata = dut.system_i.zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RDATA;
  assign ps_rresp = dut.system_i.zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RRESP;
  assign ps_rlast = dut.system_i.zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RLAST;
  assign ps_rvalid = dut.system_i.zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RVALID;

  logic mig0_clk;
  logic mig0_rst;
  always #1667 mig0_clk = ~mig0_clk;

  logic awready_0, wready_0, bvalid_0, arready_0, rvalid_0;
  logic [1:0] bid_0, bresp_0, rid_0, rresp_0;
  logic [511:0] rdata_0;
  logic rlast_0;

  axi_mem_512 mem0 (
    .clk(mig0_clk), .rst(mig0_rst),
    .awvalid(dut.system_i.mig0_ic_M00_AXI_AWVALID),
    .awready(awready_0),
    .awid(dut.system_i.mig0_ic_M00_AXI_AWID),
    .awaddr(dut.system_i.mig0_ic_M00_AXI_AWADDR),
    .awlen(dut.system_i.mig0_ic_M00_AXI_AWLEN),
    .awsize(dut.system_i.mig0_ic_M00_AXI_AWSIZE),
    .awburst(dut.system_i.mig0_ic_M00_AXI_AWBURST),
    .wdata(dut.system_i.mig0_ic_M00_AXI_WDATA),
    .wstrb(dut.system_i.mig0_ic_M00_AXI_WSTRB),
    .wlast(dut.system_i.mig0_ic_M00_AXI_WLAST),
    .wvalid(dut.system_i.mig0_ic_M00_AXI_WVALID),
    .wready(wready_0),
    .bid(bid_0), .bresp(bresp_0), .bvalid(bvalid_0),
    .bready(dut.system_i.mig0_ic_M00_AXI_BREADY),
    .arvalid(dut.system_i.mig0_ic_M00_AXI_ARVALID),
    .arready(arready_0),
    .arid(dut.system_i.mig0_ic_M00_AXI_ARID),
    .araddr(dut.system_i.mig0_ic_M00_AXI_ARADDR),
    .arlen(dut.system_i.mig0_ic_M00_AXI_ARLEN),
    .arsize(dut.system_i.mig0_ic_M00_AXI_ARSIZE),
    .arburst(dut.system_i.mig0_ic_M00_AXI_ARBURST),
    .rid(rid_0), .rdata(rdata_0), .rresp(rresp_0), .rlast(rlast_0),
    .rvalid(rvalid_0), .rready(dut.system_i.mig0_ic_M00_AXI_RREADY)
  );

  // Same RTL bridge used by the fabric, but instantiated locally so the test can drive the Core
  // master without colliding with otpu_board's own native-memory scoreboard. This validates the
  // shared mig0_ic path and bridge logic, not the integrated Core-to-fabric wrapper wiring.
  otpu_native_axi_ch #(
    .MAX_BURST(64), .CMD_DEPTH(64), .WD_DEPTH(64), .RD_DEPTH(128),
    .EVT_DEPTH(16), .COALESCE_WAIT(32), .TIMEOUT_CYCLES(1000000), .IDW(1)
  ) u_test_core (
    .clk(ps_clk), .rst(~peripheral_rstn),
    .n_cvalid(core_n_cvalid[0]), .n_cready(core_n_cready[0]),
    .n_cwe(core_n_cwe[0]), .n_caddr(core_n_caddr[0]),
    .n_wvalid(core_n_wvalid[0]), .n_wready(core_n_wready[0]),
    .n_wdata(core_n_wdata[0]), .n_wmask(core_n_wmask[0]),
    .n_rvalid(core_n_rvalid[0]), .n_rdata(core_n_rdata[0]),
    .n_wdone(core_n_wdone[0]), .n_err(core_n_err[0]),
    .aclk(mig0_clk), .arst(mig0_rst),
    .m_awid(test_core_awid), .m_awaddr(test_core_awaddr),
    .m_awlen(test_core_awlen), .m_awsize(test_core_awsize),
    .m_awburst(test_core_awburst), .m_awlock(test_core_awlock),
    .m_awcache(test_core_awcache), .m_awprot(test_core_awprot),
    .m_awqos(test_core_awqos), .m_awvalid(test_core_awvalid),
    .m_awready(dut.system_i.otpu_fabric_M_AXI_CORE0_AWREADY),
    .m_wdata(test_core_wdata), .m_wstrb(test_core_wstrb),
    .m_wlast(test_core_wlast), .m_wvalid(test_core_wvalid),
    .m_wready(dut.system_i.otpu_fabric_M_AXI_CORE0_WREADY),
    .m_bid(dut.system_i.otpu_fabric_M_AXI_CORE0_BID),
    .m_bresp(dut.system_i.otpu_fabric_M_AXI_CORE0_BRESP),
    .m_bvalid(dut.system_i.otpu_fabric_M_AXI_CORE0_BVALID),
    .m_bready(test_core_bready),
    .m_arid(test_core_arid), .m_araddr(test_core_araddr),
    .m_arlen(test_core_arlen), .m_arsize(test_core_arsize),
    .m_arburst(test_core_arburst), .m_arlock(test_core_arlock),
    .m_arcache(test_core_arcache), .m_arprot(test_core_arprot),
    .m_arqos(test_core_arqos), .m_arvalid(test_core_arvalid),
    .m_arready(dut.system_i.otpu_fabric_M_AXI_CORE0_ARREADY),
    .m_rid(dut.system_i.otpu_fabric_M_AXI_CORE0_RID),
    .m_rdata(dut.system_i.otpu_fabric_M_AXI_CORE0_RDATA),
    .m_rresp(dut.system_i.otpu_fabric_M_AXI_CORE0_RRESP),
    .m_rlast(dut.system_i.otpu_fabric_M_AXI_CORE0_RLAST),
    .m_rvalid(dut.system_i.otpu_fabric_M_AXI_CORE0_RVALID),
    .m_rready(test_core_rready)
  );

  task automatic cdma_write(input logic [39:0] base, input logic [39:0] off,
                            input logic [31:0] value);
    xil_axi_resp_t response;
    bit [8*4096-1:0] data_block;
    begin
      data_block = '0;
      data_block[31:0] = value;
      dut.system_i.zynq_ultra_ps_e_0.inst.M_AXI_HPM0_FPD.mst.AXI4_WRITE_BURST(
        .id(0), .addr(base + off), .len(8'd0), .size(XIL_AXI_SIZE_4BYTE),
        .burst(XIL_AXI_BURST_TYPE_INCR), .lock(XIL_AXI_ALOCK_NOLOCK),
        .cache(4'd0), .prot(xil_axi_prot_t'(0)), .region(4'd0), .qos(4'd0),
        .awuser('0), .data(data_block), .wuser('0), .resp(response));
      if (response != XIL_AXI_RESP_OKAY)
        $fatal(1, "CDMA AXI-Lite write failed addr=%h resp=%0d",
               base + off, response);
      if ($test$plusargs("debug_control"))
        $display("CDMA_CTRL WRITE addr=%h data=%h", base + off, value);
    end
  endtask

  task automatic cdma_read(input logic [39:0] base, input logic [39:0] off,
                           output logic [31:0] value);
    xil_axi_resp_t response;
    xil_axi_resp_t [255:0] responses;
    xil_axi_data_beat [255:0] ruser;
    bit [8*4096-1:0] data_block;
    begin
      data_block = '0;
      responses = '0;
      ruser = '0;
      dut.system_i.zynq_ultra_ps_e_0.inst.M_AXI_HPM0_FPD.mst.AXI4_READ_BURST(
        .id(0), .addr(base + off), .len(8'd0), .size(XIL_AXI_SIZE_4BYTE),
        .burst(XIL_AXI_BURST_TYPE_INCR), .lock(XIL_AXI_ALOCK_NOLOCK),
        .cache(4'd0), .prot(xil_axi_prot_t'(0)), .region(4'd0), .qos(4'd0),
        .aruser('0), .data(data_block), .resp(responses), .ruser(ruser));
      response = responses[0];
      if (response != XIL_AXI_RESP_OKAY)
        $fatal(1, "CDMA AXI-Lite read failed addr=%h resp=%0d",
               base + off, response);
      value = data_block[31:0];
      if ($test$plusargs("debug_control"))
        $display("CDMA_CTRL READ addr=%h data=%h", base + off, value);
    end
  endtask

  task automatic wait_idle(input logic [39:0] base);
    logic [31:0] status;
    begin
      for (int i = 0; i < 100000; i++) begin
        cdma_read(base, CDMASR, status);
        if (status[1] && !status[4] && !status[5] && !status[6] && !status[7])
          return;
        #1000;
      end
      $fatal(1, "CDMA did not become idle/error-free base=%h status=%h", base, status);
    end
  endtask

  task automatic wait_busy_then_idle(input logic [39:0] base);
    logic [31:0] status;
    logic seen_busy;
    seen_busy = 1'b0;
    for (int i = 0; i < 100000; i++) begin
      cdma_read(base, CDMASR, status);
      if (i == 0 && $test$plusargs("debug_control"))
        $display("CDMA_STATUS base=%h status=%h", base, status);
      if (status[4] || status[5] || status[6] || status[7])
        $fatal(1, "CDMA error base=%h status=%h", base, status);
      if (!status[1])
        seen_busy = 1'b1;
      if (seen_busy && status[1])
        return;
      #1000;
    end
    $fatal(1, "CDMA never completed base=%h seen_busy=%0b status=%h",
           base, seen_busy, status);
  endtask

  task automatic configure_copy(input logic [39:0] base,
                                input logic [63:0] src,
                                input logic [63:0] dst);
    logic [31:0] rd;
    begin
      cdma_write(base, CDMACR, 32'h0000_0001);
      cdma_write(base, SA, src[31:0]);
      cdma_write(base, SA_HI, src[63:32]);
      cdma_write(base, DA, dst[31:0]);
      cdma_write(base, DA_HI, dst[63:32]);
      cdma_read(base, SA, rd);
      if (rd !== src[31:0])
        $fatal(1, "CDMA SA low readback mismatch base=%h got=%h expected=%h",
               base, rd, src[31:0]);
      cdma_read(base, SA_HI, rd);
      if (rd !== src[63:32])
        $fatal(1, "CDMA SA high readback mismatch base=%h got=%h expected=%h",
               base, rd, src[63:32]);
      cdma_read(base, DA, rd);
      if (rd !== dst[31:0])
        $fatal(1, "CDMA DA low readback mismatch base=%h got=%h expected=%h",
               base, rd, dst[31:0]);
      cdma_read(base, DA_HI, rd);
      if (rd !== dst[63:32])
        $fatal(1, "CDMA DA high readback mismatch base=%h got=%h expected=%h",
               base, rd, dst[63:32]);
    end
  endtask

  task automatic start_copy(input logic [39:0] base, input int nbytes);
    begin
      cdma_write(base, BTT, nbytes[31:0]);
      wait_busy_then_idle(base);
    end
  endtask

  task automatic simple_copy(input logic [39:0] base,
                             input logic [63:0] src,
                             input logic [63:0] dst,
                             input int nbytes);
    begin
      configure_copy(base, src, dst);
      start_copy(base, nbytes);
    end
  endtask

  function automatic logic [511:0] pattern(input int beat);
    logic [511:0] value;
    value = '0;
    for (int w = 0; w < 16; w++)
      value[w*32 +: 32] =
        32'hA500_0000 ^ (beat * 32'h0101_0101) ^
        (pattern_iter * 32'h0001_0001) ^ w;
    return value;
  endfunction

  always_ff @(posedge ps_clk) begin
    if ($test$plusargs("debug_control")) begin
      if (dut.system_i.ctrl_ic_M02_AXI_AWVALID &&
          dut.system_i.ctrl_ic_M02_AXI_AWREADY)
        $display("CTRL_M02 AW addr=%h",
                 dut.system_i.ctrl_ic_M02_AXI_AWADDR);
      if (dut.system_i.ctrl_ic_M02_AXI_WVALID &&
          dut.system_i.ctrl_ic_M02_AXI_WREADY)
        $display("CTRL_M02 W data=%h",
                 dut.system_i.ctrl_ic_M02_AXI_WDATA);
      if (dut.system_i.ctrl_ic_M02_AXI_ARVALID &&
          dut.system_i.ctrl_ic_M02_AXI_ARREADY)
        $display("CTRL_M02 AR addr=%h",
                 dut.system_i.ctrl_ic_M02_AXI_ARADDR);
      if (dut.system_i.ctrl_ic_M02_AXI_RVALID &&
          dut.system_i.ctrl_ic_M02_AXI_RREADY)
        $display("CTRL_M02 R data=%h resp=%0d",
                 dut.system_i.ctrl_ic_M02_AXI_RDATA,
                 dut.system_i.ctrl_ic_M02_AXI_RRESP);
    end
    if (dut.system_i.c2h_route_M00_AXI_WVALID &&
        dut.system_i.c2h_route_M00_AXI_WREADY) begin
      expected_beat = pattern(c2h_ps_wbeats / 4);
      if (dut.system_i.c2h_route_M00_AXI_WDATA !==
          expected_beat[(c2h_ps_wbeats % 4) * 128 +: 128])
        $fatal(1, "C2H PS WDATA mismatch beat=%0d got=%h expected=%h",
               c2h_ps_wbeats, dut.system_i.c2h_route_M00_AXI_WDATA,
               expected_beat[(c2h_ps_wbeats % 4) * 128 +: 128]);
      c2h_ps_wbeats <= c2h_ps_wbeats + 1;
    end
    if (dut.system_i.h2c_route_M00_AXI_RVALID &&
        dut.system_i.h2c_route_M00_AXI_RREADY)
      h2c_ps_rbeats <= h2c_ps_rbeats + 1;
    if (core_read_capture && core_n_rvalid[0]) begin
      if (core_read_count < 64)
        core_read_mem[core_read_count] <= core_n_rdata[0];
      core_read_count <= core_read_count + 1;
    end
    if (core_n_cvalid[0] && core_n_cready[0])
      core_cmd_handshakes <= core_cmd_handshakes + 1;
  end

  task automatic native_read_chunk(input int base_beat, input int beats);
    core_read_capture = 1'b1;
    core_read_count = 0;
    core_cmd_handshakes = 0;
    for (int beat = 0; beat < beats; beat++) begin
      core_n_cvalid[0] = 1'b1;
      core_n_cwe[0] = 1'b0;
      core_n_caddr[0] = 25'(base_beat + beat);
      do
        @(posedge ps_clk);
      while (core_n_cready[0] !== 1'b1);
      @(negedge ps_clk);
      core_n_cvalid[0] = 1'b0;
      #1000;
    end
    if (core_cmd_handshakes != beats)
      $fatal(1, "Core native read command count mismatch got=%0d expected=%0d",
             core_cmd_handshakes, beats);
    for (int cyc = 0; cyc < 100000 && core_read_count < beats; cyc++)
      @(posedge ps_clk);
    #1000;
    core_read_capture = 1'b0;
    if (core_read_count != beats)
      $fatal(1, "Core native read count mismatch got=%0d expected=%0d",
             core_read_count, beats);
  endtask

  task automatic native_write_chunk(input int base_beat, input int beats);
    logic [15:0] done_base;
    logic [15:0] done_delta;
    logic cmd_done, wd_done;
    logic wdone_ok;
    done_base = core_n_wdone[0];
    for (int beat = 0; beat < beats; beat++) begin
      core_n_cvalid[0] = 1'b1;
      core_n_cwe[0] = 1'b1;
      core_n_caddr[0] = 25'(base_beat + beat);
      core_n_wvalid[0] = 1'b1;
      core_n_wdata[0] = pattern(beat);
      core_n_wmask[0] = '1;
      cmd_done = 1'b0;
      wd_done = 1'b0;
      while (!cmd_done || !wd_done) begin
        @(posedge ps_clk);
        if (core_n_cready[0] === 1'b1)
          cmd_done = 1'b1;
        if (core_n_wready[0] === 1'b1)
          wd_done = 1'b1;
        @(negedge ps_clk);
        if (cmd_done)
          core_n_cvalid[0] = 1'b0;
        if (wd_done)
          core_n_wvalid[0] = 1'b0;
      end
    end
    wdone_ok = 1'b0;
    for (int cyc = 0; cyc < 100000; cyc++) begin
      @(posedge ps_clk);
      done_delta = core_n_wdone[0] - done_base;
      if (done_delta == 16'(beats)) begin
        wdone_ok = 1'b1;
        break;
      end
    end
    if (!wdone_ok)
      $fatal(1, "Core native write completion timeout base=%0d",
             done_base);
  endtask

  always @* begin
    force dut.system_i.ddr4_0_c0_ddr4_ui_clk = mig0_clk;
    force dut.system_i.ddr4_0_c0_ddr4_ui_clk_sync_rst = mig0_rst;
    force dut.system_i.rst_100_peripheral_aresetn = peripheral_rstn;
    force dut.system_i.mig0_ic_M00_AXI_AWREADY = awready_0;
    force dut.system_i.mig0_ic_M00_AXI_WREADY = wready_0;
    force dut.system_i.mig0_ic_M00_AXI_BID = bid_0;
    force dut.system_i.mig0_ic_M00_AXI_BRESP = bresp_0;
    force dut.system_i.mig0_ic_M00_AXI_BVALID = bvalid_0;
    force dut.system_i.mig0_ic_M00_AXI_ARREADY = arready_0;
    force dut.system_i.mig0_ic_M00_AXI_RID = rid_0;
    force dut.system_i.mig0_ic_M00_AXI_RDATA = rdata_0;
    force dut.system_i.mig0_ic_M00_AXI_RRESP = rresp_0;
    force dut.system_i.mig0_ic_M00_AXI_RLAST = rlast_0;
    force dut.system_i.mig0_ic_M00_AXI_RVALID = rvalid_0;
    force dut.system_i.zynq_ultra_ps_e_0.inst.S_AXI_HP1_FPD.slave.IF.AWREADY = hp1_awready;
    force dut.system_i.zynq_ultra_ps_e_0.inst.S_AXI_HP1_FPD.slave.IF.WREADY = hp1_wready;
    force dut.system_i.zynq_ultra_ps_e_0.inst.S_AXI_HP1_FPD.slave.IF.BRESP = hp1_bresp;
    force dut.system_i.zynq_ultra_ps_e_0.inst.S_AXI_HP1_FPD.slave.IF.BVALID = hp1_bvalid;
    force dut.system_i.zynq_ultra_ps_e_0.inst.S_AXI_HP0_FPD.slave.IF.ARREADY = hp0_arready;
    force dut.system_i.zynq_ultra_ps_e_0.inst.S_AXI_HP0_FPD.slave.IF.RDATA = hp0_rdata;
    force dut.system_i.zynq_ultra_ps_e_0.inst.S_AXI_HP0_FPD.slave.IF.RRESP = hp0_rresp;
    force dut.system_i.zynq_ultra_ps_e_0.inst.S_AXI_HP0_FPD.slave.IF.RLAST = hp0_rlast;
    force dut.system_i.zynq_ultra_ps_e_0.inst.S_AXI_HP0_FPD.slave.IF.RVALID = hp0_rvalid;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_AWID = test_core_awid;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_AWADDR = test_core_awaddr;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_AWLEN = test_core_awlen;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_AWSIZE = test_core_awsize;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_AWBURST = test_core_awburst;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_AWVALID = test_core_awvalid;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_WDATA = test_core_wdata;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_WSTRB = test_core_wstrb;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_WLAST = test_core_wlast;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_WVALID = test_core_wvalid;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_BREADY = test_core_bready;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_ARID = test_core_arid;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_ARADDR = test_core_araddr;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_ARLEN = test_core_arlen;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_ARSIZE = test_core_arsize;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_ARBURST = test_core_arburst;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_ARVALID = test_core_arvalid;
    force dut.system_i.otpu_fabric_M_AXI_CORE0_RREADY = test_core_rready;
  end

  initial begin
    logic [511:0] got;
    logic [31:0] probe_status;
    ddr_clk0_clk_p = 1'b0;
    ddr_clk1_clk_p = 1'b0;
    UART_0_rxd = 1'b1;
    mig0_clk = 1'b0;
    mig0_rst = 1'b1;
    peripheral_rstn = 1'b0;
    ps_awid = '0;
    ps_awaddr = '0;
    ps_awlen = '0;
    ps_awsize = '0;
    ps_awburst = '0;
    ps_awvalid = 1'b0;
    ps_wdata = '0;
    ps_wstrb = '0;
    ps_wlast = 1'b0;
    ps_wvalid = 1'b0;
    ps_bready = 1'b0;
    ps_arid = '0;
    ps_araddr = '0;
    ps_arlen = '0;
    ps_arsize = '0;
    ps_arburst = '0;
    ps_arvalid = 1'b0;
    ps_rready = 1'b0;
    core_n_cvalid = '0;
    core_n_cwe = '0;
    core_n_caddr = '0;
    core_n_wvalid = '0;
    core_n_wdata = '0;
    core_n_wmask = '0;

    for (int beat = 0; beat < BYTES / 64; beat++)
      mem0.mem[beat] = pattern(beat);

    force dut.system_i.ddr4_0_c0_init_calib_complete = 1'b1;
    force dut.system_i.ddr4_1_c0_init_calib_complete = 1'b1;

    #20_000_000;
    mig0_rst = 1'b0;
    #5_000_000;
    peripheral_rstn = 1'b1;
    #1_000_000;

    $display("CDMA_ROUNDTRIP start C2H=%h H2C=%h", C2H_CTRL, H2C_CTRL);
    if ($test$plusargs("probe_cdma_config")) begin
      wait_idle(C2H_CTRL);
      cdma_write(C2H_CTRL, CDMACR, 32'h0000_0001);
      cdma_write(C2H_CTRL, SA, PL_BASE[31:0]);
      cdma_write(C2H_CTRL, SA_HI, PL_BASE[63:32]);
      cdma_write(C2H_CTRL, DA, PS_BASE[31:0]);
      cdma_write(C2H_CTRL, DA_HI, PS_BASE[63:32]);
      cdma_read(C2H_CTRL, SA, probe_status);
      $display("CDMA_CONFIG sa_lo=%h", probe_status);
      cdma_read(C2H_CTRL, SA_HI, probe_status);
      $display("CDMA_CONFIG sa_hi=%h", probe_status);
      cdma_read(C2H_CTRL, DA, probe_status);
      $display("CDMA_CONFIG da_lo=%h", probe_status);
      cdma_read(C2H_CTRL, DA_HI, probe_status);
      $display("CDMA_CONFIG da_hi=%h", probe_status);
      $finish;
    end
    if ($test$plusargs("probe_cdma")) begin
      cdma_read(C2H_CTRL, CDMASR, probe_status);
      $display("CDMA_PROBE c2h_status=%h", probe_status);
      $finish;
    end

    $display("CDMA_ROUNDTRIP C2H start");
    simple_copy(C2H_CTRL, PL_BASE, PS_BASE, BYTES);
    if (c2h_ps_wbeats != BYTES / 16)
      $fatal(1, "C2H PS W beat count mismatch got=%0d expected=%0d",
             c2h_ps_wbeats, BYTES / 16);
    $display("PASS CDMA C2H PL=%h -> PS=%h bytes=%0d", PL_BASE, PS_BASE, BYTES);

    $display("CDMA_ROUNDTRIP H2C start");
    simple_copy(H2C_CTRL, PS_BASE, PL_DST, BYTES);
    if (h2c_ps_rbeats != BYTES / 16)
      $fatal(1, "H2C PS R beat count mismatch got=%0d expected=%0d",
             h2c_ps_rbeats, BYTES / 16);
    $display("PASS CDMA H2C PS=%h -> PL=%h bytes=%0d", PS_BASE, PL_DST, BYTES);

    for (int beat = 0; beat < BYTES / 64; beat++) begin
      got = mem0.mem[(PL_DST[31:6]) + beat];
      if (got !== pattern(beat))
        $fatal(1, "roundtrip mismatch beat=%0d got=%h expected=%h",
               beat, got, pattern(beat));
    end

    $display("PASS tb_bd_cdma_roundtrip bytes=%0d cdma=h2c,c2h", BYTES);

    native_read_chunk(PL_DST[31:6], BYTES / 64);
    for (int beat = 0; beat < BYTES / 64; beat++)
      if (core_read_mem[beat] !== pattern(beat))
        $fatal(1, "host-to-core shared DDR mismatch beat=%0d got=%h expected=%h",
               beat, core_read_mem[beat], pattern(beat));
    $display("PASS shared DDR H2C -> Core read beats=%0d", BYTES / 64);

    native_write_chunk(PL_CORE[31:6], BYTES / 64);
    c2h_ps_wbeats = 0;
    simple_copy(C2H_CTRL, PL_CORE, PS_BASE, BYTES);
    if (c2h_ps_wbeats != BYTES / 16)
      $fatal(1, "Core-to-C2H PS W beat count mismatch got=%0d expected=%0d",
             c2h_ps_wbeats, BYTES / 16);
    $display("PASS shared DDR Core write -> C2H beats=%0d", BYTES / 64);

    configure_copy(C2H_CTRL, PL_CORE, PS_BASE);
    configure_copy(H2C_CTRL, PS_BASE, PL_DST);
    for (int iter = 0; iter < STRESS_ITERS; iter++) begin
      pattern_iter = iter + 1;
      native_write_chunk(PL_CORE[31:6], STRESS_BYTES / 64);

      c2h_ps_wbeats = 0;
      start_copy(C2H_CTRL, STRESS_BYTES);
      if (c2h_ps_wbeats != STRESS_BYTES / 16)
        $fatal(1, "stress iter=%0d C2H W beats got=%0d expected=%0d",
               iter, c2h_ps_wbeats, STRESS_BYTES / 16);

      h2c_ps_rbeats = 0;
      start_copy(H2C_CTRL, STRESS_BYTES);
      if (h2c_ps_rbeats != STRESS_BYTES / 16)
        $fatal(1, "stress iter=%0d H2C R beats got=%0d expected=%0d",
               iter, h2c_ps_rbeats, STRESS_BYTES / 16);

      native_read_chunk(PL_DST[31:6], STRESS_BYTES / 64);
      for (int beat = 0; beat < STRESS_BYTES / 64; beat++)
        if (core_read_mem[beat] !== pattern(beat))
          $fatal(1, "stress iter=%0d Core read mismatch beat=%0d got=%h expected=%h",
                 iter, beat, core_read_mem[beat], pattern(beat));

      $display("BUS_STRESS iter=%0d PASS bytes_per_direction=%0d",
               iter, STRESS_BYTES);
    end
    $display("PASS repeated bus stress iters=%0d bytes_per_direction=%0d",
             STRESS_ITERS, STRESS_BYTES);

    $display("PASS tb_bd_shared_ddr_consistency bytes=%0d", BYTES);
    $finish;
  end

  initial begin
    #5_000_000_000;
    $fatal(1, "tb_bd_cdma_roundtrip global timeout");
  end
endmodule

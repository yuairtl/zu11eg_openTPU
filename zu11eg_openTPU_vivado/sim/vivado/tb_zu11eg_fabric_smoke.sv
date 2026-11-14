`timescale 1ns / 1ps

module tb_axi_mem_stub #(
  parameter int DW = 128,
  parameter int AW = 32,
  parameter int IDW = 1
) (
  input  logic             clk,
  input  logic             rst,
  input  logic [AW-1:0]    s_awaddr,
  input  logic [IDW-1:0]   s_awid,
  input  logic [7:0]       s_awlen,
  input  logic [2:0]       s_awsize,
  input  logic [1:0]       s_awburst,
  input  logic             s_awvalid,
  output logic             s_awready,
  input  logic [DW-1:0]    s_wdata,
  input  logic [DW/8-1:0]  s_wstrb,
  input  logic             s_wlast,
  input  logic             s_wvalid,
  output logic             s_wready,
  output logic [IDW-1:0]   s_bid,
  output logic [1:0]       s_bresp,
  output logic             s_bvalid,
  input  logic             s_bready,
  input  logic [AW-1:0]    s_araddr,
  input  logic [IDW-1:0]   s_arid,
  input  logic [7:0]       s_arlen,
  input  logic [2:0]       s_arsize,
  input  logic [1:0]       s_arburst,
  input  logic             s_arvalid,
  output logic             s_arready,
  output logic [IDW-1:0]   s_rid,
  output logic [DW-1:0]    s_rdata,
  output logic [1:0]       s_rresp,
  output logic             s_rlast,
  output logic             s_rvalid,
  input  logic             s_rready,
  output logic [31:0]      write_count,
  output logic [31:0]      read_count
);
  logic [DW-1:0] mem [0:255];
  logic [IDW-1:0] awid_q, arid_q;
  logic [AW-1:0] awaddr_q;
  logic [DW-1:0] wdata_q;
  logic [31:0] wc_q, rc_q;
  logic bvalid_q, rvalid_q;
  logic aw_seen_q, w_seen_q;
  logic [AW-1:0] awaddr_next;
  logic [DW-1:0] wdata_next;

  assign s_awready = !rst && !aw_seen_q && !bvalid_q;
  assign s_wready  = !rst && !w_seen_q && !bvalid_q;
  assign awaddr_next = (s_awvalid && s_awready) ? s_awaddr : awaddr_q;
  assign wdata_next  = (s_wvalid && s_wready) ? s_wdata : wdata_q;
  assign s_arready = !rst && !rvalid_q;
  assign s_bvalid  = bvalid_q;
  assign s_bid     = awid_q;
  assign s_bresp   = 2'b00;
  assign s_rvalid  = rvalid_q;
  assign s_rid     = arid_q;
  assign s_rdata   = mem[s_araddr[9:2]];
  assign s_rresp   = 2'b00;
  assign s_rlast   = 1'b1;
  assign write_count = wc_q;
  assign read_count  = rc_q;

  initial begin
    for (int i = 0; i < 256; i++)
      mem[i] = '0;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      bvalid_q <= 1'b0;
      rvalid_q <= 1'b0;
      awid_q <= '0;
      arid_q <= '0;
      awaddr_q <= '0;
      wdata_q <= '0;
      aw_seen_q <= 1'b0;
      w_seen_q <= 1'b0;
      wc_q <= '0;
      rc_q <= '0;
    end else begin
      if (s_awvalid && s_awready) begin
        awid_q <= s_awid;
        awaddr_q <= s_awaddr;
        aw_seen_q <= 1'b1;
        wc_q <= wc_q + 1'b1;
      end
      if (s_wvalid && s_wready) begin
        wdata_q <= s_wdata;
        w_seen_q <= 1'b1;
      end
      if ((aw_seen_q || (s_awvalid && s_awready)) &&
          (w_seen_q  || (s_wvalid && s_wready)) && !bvalid_q) begin
        mem[awaddr_next[9:2]] <= wdata_next;
        bvalid_q <= 1'b1;
        aw_seen_q <= 1'b0;
        w_seen_q <= 1'b0;
      end
      if (bvalid_q && s_bready)
        bvalid_q <= 1'b0;

      if (s_arvalid && s_arready && !rvalid_q) begin
        arid_q <= s_arid;
        rc_q <= rc_q + 1'b1;
        rvalid_q <= 1'b1;
      end
      if (rvalid_q && s_rready)
        rvalid_q <= 1'b0;
    end
  end
endmodule

module tb_zu11eg_fabric_smoke;
  logic core_clk, core_clk_f, core_rstn;
  logic mig0_clk, mig0_rst, mig1_clk, mig1_rst;
  logic [1:0] calib;
  logic dci_locked;

  logic [11:0] s_axi_ctrl_awaddr, s_axi_ctrl_araddr;
  logic        s_axi_ctrl_awvalid, s_axi_ctrl_wvalid;
  logic        s_axi_ctrl_bready, s_axi_ctrl_arvalid, s_axi_ctrl_rready;
  logic [31:0] s_axi_ctrl_wdata, s_axi_ctrl_rdata;
  logic [3:0]  s_axi_ctrl_wstrb;
  logic        s_axi_ctrl_awready, s_axi_ctrl_wready, s_axi_ctrl_bvalid;
  logic        s_axi_ctrl_arready, s_axi_ctrl_rvalid;
  logic [1:0]  s_axi_ctrl_bresp, s_axi_ctrl_rresp;

  logic [63:0] s_axi_host_awaddr, s_axi_host_araddr;
  logic [0:0]  s_axi_host_awid, s_axi_host_arid;
  logic [7:0]  s_axi_host_awlen, s_axi_host_arlen;
  logic [2:0]  s_axi_host_awsize, s_axi_host_arsize;
  logic [1:0]  s_axi_host_awburst, s_axi_host_arburst;
  logic        s_axi_host_awvalid, s_axi_host_awready;
  logic [127:0] s_axi_host_wdata;
  logic [15:0] s_axi_host_wstrb;
  logic        s_axi_host_wlast, s_axi_host_wvalid, s_axi_host_wready;
  logic [0:0]  s_axi_host_bid;
  logic [1:0]  s_axi_host_bresp;
  logic        s_axi_host_bvalid, s_axi_host_bready;
  logic        s_axi_host_arvalid, s_axi_host_arready;
  logic [0:0]  s_axi_host_rid;
  logic [127:0] s_axi_host_rdata;
  logic [1:0]  s_axi_host_rresp;
  logic        s_axi_host_rlast, s_axi_host_rvalid, s_axi_host_rready;

  logic [31:0] m_axi_host0_awaddr;
  logic [0:0]  m_axi_host0_awid;
  logic [7:0]  m_axi_host0_awlen;
  logic [2:0]  m_axi_host0_awsize;
  logic [1:0]  m_axi_host0_awburst;
  logic        m_axi_host0_awvalid, m_axi_host0_awready;
  logic [127:0] m_axi_host0_wdata;
  logic [15:0] m_axi_host0_wstrb;
  logic        m_axi_host0_wlast, m_axi_host0_wvalid, m_axi_host0_wready;
  logic [0:0]  m_axi_host0_bid;
  logic [1:0]  m_axi_host0_bresp;
  logic        m_axi_host0_bvalid, m_axi_host0_bready;
  logic [31:0] m_axi_host0_araddr;
  logic [0:0]  m_axi_host0_arid;
  logic [7:0]  m_axi_host0_arlen;
  logic [2:0]  m_axi_host0_arsize;
  logic [1:0]  m_axi_host0_arburst;
  logic        m_axi_host0_arvalid, m_axi_host0_arready;
  logic [0:0]  m_axi_host0_rid;
  logic [127:0] m_axi_host0_rdata;
  logic [1:0]  m_axi_host0_rresp;
  logic        m_axi_host0_rlast, m_axi_host0_rvalid, m_axi_host0_rready;

  logic [31:0] m_axi_host1_awaddr;
  logic [0:0]  m_axi_host1_awid;
  logic [7:0]  m_axi_host1_awlen;
  logic [2:0]  m_axi_host1_awsize;
  logic [1:0]  m_axi_host1_awburst;
  logic        m_axi_host1_awvalid, m_axi_host1_awready;
  logic [127:0] m_axi_host1_wdata;
  logic [15:0] m_axi_host1_wstrb;
  logic        m_axi_host1_wlast, m_axi_host1_wvalid, m_axi_host1_wready;
  logic [0:0]  m_axi_host1_bid;
  logic [1:0]  m_axi_host1_bresp;
  logic        m_axi_host1_bvalid, m_axi_host1_bready;
  logic [31:0] m_axi_host1_araddr;
  logic [0:0]  m_axi_host1_arid;
  logic [7:0]  m_axi_host1_arlen;
  logic [2:0]  m_axi_host1_arsize;
  logic [1:0]  m_axi_host1_arburst;
  logic        m_axi_host1_arvalid, m_axi_host1_arready;
  logic [0:0]  m_axi_host1_rid;
  logic [127:0] m_axi_host1_rdata;
  logic [1:0]  m_axi_host1_rresp;
  logic        m_axi_host1_rlast, m_axi_host1_rvalid, m_axi_host1_rready;

  logic [31:0] m_axi_core0_awaddr;
  logic        m_axi_core0_awid;
  logic [7:0]  m_axi_core0_awlen;
  logic [2:0]  m_axi_core0_awsize;
  logic [1:0]  m_axi_core0_awburst;
  logic        m_axi_core0_awvalid, m_axi_core0_awready;
  logic [511:0] m_axi_core0_wdata;
  logic [63:0] m_axi_core0_wstrb;
  logic        m_axi_core0_wlast, m_axi_core0_wvalid, m_axi_core0_wready;
  logic        m_axi_core0_bid;
  logic [1:0]  m_axi_core0_bresp;
  logic        m_axi_core0_bvalid, m_axi_core0_bready;
  logic [31:0] m_axi_core0_araddr;
  logic        m_axi_core0_arid;
  logic [7:0]  m_axi_core0_arlen;
  logic [2:0]  m_axi_core0_arsize;
  logic [1:0]  m_axi_core0_arburst;
  logic        m_axi_core0_arvalid, m_axi_core0_arready;
  logic        m_axi_core0_rid;
  logic [511:0] m_axi_core0_rdata;
  logic [1:0]  m_axi_core0_rresp;
  logic        m_axi_core0_rlast, m_axi_core0_rvalid, m_axi_core0_rready;

  logic [31:0] m_axi_core1_awaddr;
  logic        m_axi_core1_awid;
  logic [7:0]  m_axi_core1_awlen;
  logic [2:0]  m_axi_core1_awsize;
  logic [1:0]  m_axi_core1_awburst;
  logic        m_axi_core1_awvalid, m_axi_core1_awready;
  logic [511:0] m_axi_core1_wdata;
  logic [63:0] m_axi_core1_wstrb;
  logic        m_axi_core1_wlast, m_axi_core1_wvalid, m_axi_core1_wready;
  logic        m_axi_core1_bid;
  logic [1:0]  m_axi_core1_bresp;
  logic        m_axi_core1_bvalid, m_axi_core1_bready;
  logic [31:0] m_axi_core1_araddr;
  logic        m_axi_core1_arid;
  logic [7:0]  m_axi_core1_arlen;
  logic [2:0]  m_axi_core1_arsize;
  logic [1:0]  m_axi_core1_arburst;
  logic        m_axi_core1_arvalid, m_axi_core1_arready;
  logic        m_axi_core1_rid;
  logic [511:0] m_axi_core1_rdata;
  logic [1:0]  m_axi_core1_rresp;
  logic        m_axi_core1_rlast, m_axi_core1_rvalid, m_axi_core1_rready;

  logic [31:0] host0_writes, host0_reads, host1_writes, host1_reads;
  logic [31:0] core0_writes, core0_reads, core1_writes, core1_reads;
  logic [31:0] host_aw_hs_count, host_w_hs_count, host_ar_hs_count;

  always #5.0 core_clk = ~core_clk;
  always #2.5 core_clk_f = ~core_clk_f;
  always #1.6667 mig0_clk = ~mig0_clk;
  always #1.6667 mig1_clk = ~mig1_clk;

  always_ff @(posedge core_clk) begin
    if (!core_rstn) begin
      host_aw_hs_count <= '0;
      host_w_hs_count <= '0;
      host_ar_hs_count <= '0;
    end else begin
      if (s_axi_host_awvalid && s_axi_host_awready)
        host_aw_hs_count <= host_aw_hs_count + 1'b1;
      if (s_axi_host_wvalid && s_axi_host_wready)
        host_w_hs_count <= host_w_hs_count + 1'b1;
      if (s_axi_host_arvalid && s_axi_host_arready)
        host_ar_hs_count <= host_ar_hs_count + 1'b1;
    end
  end

  otpu_zu11eg_fabric dut (.*);

  tb_axi_mem_stub #(.DW(128), .AW(32), .IDW(1)) host0_stub (
    .clk(core_clk), .rst(!core_rstn),
    .s_awaddr(m_axi_host0_awaddr), .s_awid(m_axi_host0_awid),
    .s_awlen(m_axi_host0_awlen), .s_awsize(m_axi_host0_awsize),
    .s_awburst(m_axi_host0_awburst), .s_awvalid(m_axi_host0_awvalid),
    .s_awready(m_axi_host0_awready), .s_wdata(m_axi_host0_wdata),
    .s_wstrb(m_axi_host0_wstrb), .s_wlast(m_axi_host0_wlast),
    .s_wvalid(m_axi_host0_wvalid), .s_wready(m_axi_host0_wready),
    .s_bid(m_axi_host0_bid), .s_bresp(m_axi_host0_bresp),
    .s_bvalid(m_axi_host0_bvalid), .s_bready(m_axi_host0_bready),
    .s_araddr(m_axi_host0_araddr), .s_arid(m_axi_host0_arid),
    .s_arlen(m_axi_host0_arlen), .s_arsize(m_axi_host0_arsize),
    .s_arburst(m_axi_host0_arburst), .s_arvalid(m_axi_host0_arvalid),
    .s_arready(m_axi_host0_arready), .s_rid(m_axi_host0_rid),
    .s_rdata(m_axi_host0_rdata), .s_rresp(m_axi_host0_rresp),
    .s_rlast(m_axi_host0_rlast), .s_rvalid(m_axi_host0_rvalid),
    .s_rready(m_axi_host0_rready),
    .write_count(host0_writes), .read_count(host0_reads));

  tb_axi_mem_stub #(.DW(128), .AW(32), .IDW(1)) host1_stub (
    .clk(core_clk), .rst(!core_rstn),
    .s_awaddr(m_axi_host1_awaddr), .s_awid(m_axi_host1_awid),
    .s_awlen(m_axi_host1_awlen), .s_awsize(m_axi_host1_awsize),
    .s_awburst(m_axi_host1_awburst), .s_awvalid(m_axi_host1_awvalid),
    .s_awready(m_axi_host1_awready), .s_wdata(m_axi_host1_wdata),
    .s_wstrb(m_axi_host1_wstrb), .s_wlast(m_axi_host1_wlast),
    .s_wvalid(m_axi_host1_wvalid), .s_wready(m_axi_host1_wready),
    .s_bid(m_axi_host1_bid), .s_bresp(m_axi_host1_bresp),
    .s_bvalid(m_axi_host1_bvalid), .s_bready(m_axi_host1_bready),
    .s_araddr(m_axi_host1_araddr), .s_arid(m_axi_host1_arid),
    .s_arlen(m_axi_host1_arlen), .s_arsize(m_axi_host1_arsize),
    .s_arburst(m_axi_host1_arburst), .s_arvalid(m_axi_host1_arvalid),
    .s_arready(m_axi_host1_arready), .s_rid(m_axi_host1_rid),
    .s_rdata(m_axi_host1_rdata), .s_rresp(m_axi_host1_rresp),
    .s_rlast(m_axi_host1_rlast), .s_rvalid(m_axi_host1_rvalid),
    .s_rready(m_axi_host1_rready),
    .write_count(host1_writes), .read_count(host1_reads));

  tb_axi_mem_stub #(.DW(512), .AW(32), .IDW(1)) core0_stub (
    .clk(mig0_clk), .rst(mig0_rst),
    .s_awaddr(m_axi_core0_awaddr), .s_awid(m_axi_core0_awid),
    .s_awlen(m_axi_core0_awlen), .s_awsize(m_axi_core0_awsize),
    .s_awburst(m_axi_core0_awburst), .s_awvalid(m_axi_core0_awvalid),
    .s_awready(m_axi_core0_awready), .s_wdata(m_axi_core0_wdata),
    .s_wstrb(m_axi_core0_wstrb), .s_wlast(m_axi_core0_wlast),
    .s_wvalid(m_axi_core0_wvalid), .s_wready(m_axi_core0_wready),
    .s_bid(m_axi_core0_bid), .s_bresp(m_axi_core0_bresp),
    .s_bvalid(m_axi_core0_bvalid), .s_bready(m_axi_core0_bready),
    .s_araddr(m_axi_core0_araddr), .s_arid(m_axi_core0_arid),
    .s_arlen(m_axi_core0_arlen), .s_arsize(m_axi_core0_arsize),
    .s_arburst(m_axi_core0_arburst), .s_arvalid(m_axi_core0_arvalid),
    .s_arready(m_axi_core0_arready), .s_rid(m_axi_core0_rid),
    .s_rdata(m_axi_core0_rdata), .s_rresp(m_axi_core0_rresp),
    .s_rlast(m_axi_core0_rlast), .s_rvalid(m_axi_core0_rvalid),
    .s_rready(m_axi_core0_rready),
    .write_count(core0_writes), .read_count(core0_reads));

  tb_axi_mem_stub #(.DW(512), .AW(32), .IDW(1)) core1_stub (
    .clk(mig1_clk), .rst(mig1_rst),
    .s_awaddr(m_axi_core1_awaddr), .s_awid(m_axi_core1_awid),
    .s_awlen(m_axi_core1_awlen), .s_awsize(m_axi_core1_awsize),
    .s_awburst(m_axi_core1_awburst), .s_awvalid(m_axi_core1_awvalid),
    .s_awready(m_axi_core1_awready), .s_wdata(m_axi_core1_wdata),
    .s_wstrb(m_axi_core1_wstrb), .s_wlast(m_axi_core1_wlast),
    .s_wvalid(m_axi_core1_wvalid), .s_wready(m_axi_core1_wready),
    .s_bid(m_axi_core1_bid), .s_bresp(m_axi_core1_bresp),
    .s_bvalid(m_axi_core1_bvalid), .s_bready(m_axi_core1_bready),
    .s_araddr(m_axi_core1_araddr), .s_arid(m_axi_core1_arid),
    .s_arlen(m_axi_core1_arlen), .s_arsize(m_axi_core1_arsize),
    .s_arburst(m_axi_core1_arburst), .s_arvalid(m_axi_core1_arvalid),
    .s_arready(m_axi_core1_arready), .s_rid(m_axi_core1_rid),
    .s_rdata(m_axi_core1_rdata), .s_rresp(m_axi_core1_rresp),
    .s_rlast(m_axi_core1_rlast), .s_rvalid(m_axi_core1_rvalid),
    .s_rready(m_axi_core1_rready),
    .write_count(core1_writes), .read_count(core1_reads));

  task automatic fail(input string text);
    $display("FAIL: %s", text);
    $fatal(1, "tb_zu11eg_fabric_smoke failed");
  endtask

  task automatic ctrl_write(input logic [11:0] addr, input logic [31:0] data);
    integer n;
    begin
      n = 0;
      @(negedge core_clk);
      s_axi_ctrl_awaddr = addr;
      s_axi_ctrl_awvalid = 1'b1;
      s_axi_ctrl_wdata = data;
      s_axi_ctrl_wstrb = 4'hF;
      s_axi_ctrl_wvalid = 1'b1;
      s_axi_ctrl_bready = 1'b0;
      while (!(s_axi_ctrl_awready && s_axi_ctrl_wready)) begin
        if (++n > 1000) fail("AXI-Lite write handshake timeout");
        @(negedge core_clk);
      end
      @(negedge core_clk);
      s_axi_ctrl_awvalid = 1'b0;
      s_axi_ctrl_wvalid = 1'b0;
      n = 0;
      while (!s_axi_ctrl_bvalid) begin
        if (++n > 1000) fail("AXI-Lite write response timeout");
        @(negedge core_clk);
      end
      if (s_axi_ctrl_bresp !== 2'b00)
        fail("AXI-Lite write response");
      @(negedge core_clk);
      s_axi_ctrl_bready = 1'b1;
      @(posedge core_clk);
      #1;
      s_axi_ctrl_bready = 1'b0;
    end
  endtask

  task automatic ctrl_read(input logic [11:0] addr, input logic [31:0] expected);
    integer n;
    begin
      n = 0;
      @(negedge core_clk);
      s_axi_ctrl_araddr = addr;
      s_axi_ctrl_arvalid = 1'b1;
      s_axi_ctrl_rready = 1'b0;
      while (!s_axi_ctrl_arready) begin
        if (++n > 1000) fail("AXI-Lite read address timeout");
        @(negedge core_clk);
      end
      @(negedge core_clk);
      s_axi_ctrl_arvalid = 1'b0;
      n = 0;
      while (!s_axi_ctrl_rvalid) begin
        if (++n > 1000) fail("AXI-Lite read data timeout");
        @(negedge core_clk);
      end
      if (s_axi_ctrl_rdata !== expected)
        fail($sformatf("AXI-Lite read %h got %h expected %h",
                       addr, s_axi_ctrl_rdata, expected));
      if (s_axi_ctrl_rresp !== 2'b00)
        fail("AXI-Lite read response");
      @(negedge core_clk);
      s_axi_ctrl_rready = 1'b1;
      @(posedge core_clk);
      #1;
      s_axi_ctrl_rready = 1'b0;
    end
  endtask

  task automatic host_write(input logic [63:0] addr, input logic [127:0] data);
    integer n, aw0, w0;
    begin
      n = 0;
      @(negedge core_clk);
      aw0 = host_aw_hs_count;
      w0 = host_w_hs_count;
      s_axi_host_awaddr = addr;
      s_axi_host_awvalid = 1'b1;
      s_axi_host_awlen = 8'd0;
      s_axi_host_awsize = 3'd4;
      s_axi_host_awburst = 2'b01;
      s_axi_host_wdata = data;
      s_axi_host_wstrb = 16'hFFFF;
      s_axi_host_wlast = 1'b1;
      s_axi_host_wvalid = 1'b1;
      s_axi_host_bready = 1'b0;
      #1;
      while (host_aw_hs_count == aw0 || host_w_hs_count == w0) begin
        if (++n > 2000) fail("host write handshake timeout");
        @(negedge core_clk);
        #1;
      end
      s_axi_host_awvalid = 1'b0;
      s_axi_host_wvalid = 1'b0;
      n = 0;
      while (!s_axi_host_bvalid) begin
        if (++n > 2000) fail("host write response timeout");
        @(negedge core_clk);
      end
      if (s_axi_host_bresp !== 2'b00)
        fail("host write response");
      @(negedge core_clk);
      s_axi_host_bready = 1'b1;
      @(posedge core_clk);
      #1;
      s_axi_host_bready = 1'b0;
    end
  endtask

  task automatic host_read(input logic [63:0] addr, input logic [127:0] expected);
    integer n, ar0;
    begin
      n = 0;
      @(negedge core_clk);
      ar0 = host_ar_hs_count;
      s_axi_host_araddr = addr;
      s_axi_host_arvalid = 1'b1;
      s_axi_host_arlen = 8'd0;
      s_axi_host_arsize = 3'd4;
      s_axi_host_arburst = 2'b01;
      s_axi_host_rready = 1'b0;
      #1;
      while (host_ar_hs_count == ar0) begin
        if (++n > 2000) fail("host read address timeout");
        @(negedge core_clk);
        #1;
      end
      s_axi_host_arvalid = 1'b0;
      n = 0;
      while (!s_axi_host_rvalid) begin
        if (++n > 2000) fail("host read data timeout");
        @(negedge core_clk);
      end
      if (s_axi_host_rdata !== expected)
        fail($sformatf("host read %h got %h expected %h",
                       addr, s_axi_host_rdata, expected));
      if (s_axi_host_rresp !== 2'b00 || !s_axi_host_rlast)
        fail("host read response/last");
      @(negedge core_clk);
      s_axi_host_rready = 1'b1;
      @(posedge core_clk);
      #1;
      s_axi_host_rready = 1'b0;
    end
  endtask

  initial begin
    core_clk = 1'b0;
    core_clk_f = 1'b0;
    mig0_clk = 1'b0;
    mig1_clk = 1'b0;
    core_rstn = 1'b0;
    mig0_rst = 1'b1;
    mig1_rst = 1'b1;
    calib = 2'b00;

    s_axi_ctrl_awaddr = '0;
    s_axi_ctrl_awvalid = 1'b0;
    s_axi_ctrl_wdata = '0;
    s_axi_ctrl_wstrb = '0;
    s_axi_ctrl_wvalid = 1'b0;
    s_axi_ctrl_bready = 1'b0;
    s_axi_ctrl_araddr = '0;
    s_axi_ctrl_arvalid = 1'b0;
    s_axi_ctrl_rready = 1'b0;

    s_axi_host_awaddr = '0;
    s_axi_host_awid = '0;
    s_axi_host_awlen = '0;
    s_axi_host_awsize = '0;
    s_axi_host_awburst = '0;
    s_axi_host_awvalid = 1'b0;
    s_axi_host_wdata = '0;
    s_axi_host_wstrb = '0;
    s_axi_host_wlast = 1'b0;
    s_axi_host_wvalid = 1'b0;
    s_axi_host_bready = 1'b0;
    s_axi_host_araddr = '0;
    s_axi_host_arid = '0;
    s_axi_host_arlen = '0;
    s_axi_host_arsize = '0;
    s_axi_host_arburst = '0;
    s_axi_host_arvalid = 1'b0;
    s_axi_host_rready = 1'b0;

    #200;
    mig0_rst = 1'b0;
    mig1_rst = 1'b0;
    calib = 2'b11;
    #200;
    core_rstn = 1'b1;
    #1000;

    ctrl_read(12'h000, 32'h4F54_5055);
    ctrl_write(12'h060, 32'hA5A5_5A5A);
    ctrl_read(12'h060, 32'hA5A5_5A5A);

    host_write(64'h0000_0000_0000_0100,
               128'h0123_4567_89AB_CDEF_0011_2233_4455_6677);
    host_read(64'h0000_0000_0000_0100,
              128'h0123_4567_89AB_CDEF_0011_2233_4455_6677);

    host_write(64'h0000_0000_8000_0100,
               128'hFEDC_BA98_7654_3210_8899_AABB_CCDD_EEFF);
    host_read(64'h0000_0000_8000_0100,
              128'hFEDC_BA98_7654_3210_8899_AABB_CCDD_EEFF);

    if (host0_writes !== 1 || host0_reads !== 1)
      fail($sformatf("channel0 counts writes=%0d reads=%0d",
                     host0_writes, host0_reads));
    if (host1_writes !== 1 || host1_reads !== 1)
      fail($sformatf("channel1 counts writes=%0d reads=%0d",
                     host1_writes, host1_reads));

    $display("PASS tb_zu11eg_fabric_smoke id=OTPU host0=1/1 host1=1/1");
    $finish;
  end

  initial begin
    #100_000;
    fail("global timeout");
  end
endmodule

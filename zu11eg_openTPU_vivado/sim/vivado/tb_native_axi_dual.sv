`timescale 1ns / 1ps

module axi_beat_mem #(
  parameter int BEATS = 1024,
  parameter int SEED = 32'h1357_9bdf
) (
  input  logic clk,
  input  logic rst,
  input  logic awvalid,
  output logic awready,
  input  logic [31:0] awaddr,
  input  logic [7:0] awlen,
  input  logic [2:0] awsize,
  input  logic [1:0] awburst,
  input  logic wvalid,
  output logic wready,
  input  logic [511:0] wdata,
  input  logic [63:0] wstrb,
  input  logic wlast,
  output logic bvalid,
  input  logic bready,
  output logic [0:0] bid,
  output logic [1:0] bresp,
  input  logic arvalid,
  output logic arready,
  input  logic [31:0] araddr,
  input  logic [7:0] arlen,
  input  logic [2:0] arsize,
  input  logic [1:0] arburst,
  output logic rvalid,
  input  logic rready,
  output logic [0:0] rid,
  output logic [511:0] rdata,
  output logic [1:0] rresp,
  output logic rlast
);
  logic [511:0] mem [BEATS];
  logic [31:0] awaddr_q;
  logic [7:0] awlen_q;
  logic [7:0] wbeat;
  logic aw_active;
  logic bvalid_q;
  logic [2:0] bdelay;
  logic [31:0] araddr_q;
  logic [7:0] arlen_q;
  logic [7:0] rbeat;
  logic rvalid_q;
  logic [2:0] rdelay;
  logic [31:0] lfsr;

  initial begin
    for (int i = 0; i < BEATS; i++)
      mem[i] = '0;
  end

  assign awready = !rst && !aw_active && !bvalid_q && ((lfsr & 7) != 0);
  assign wready = !rst && aw_active && !bvalid_q && ((lfsr & 'h70) != 0);
  assign bvalid = bvalid_q;
  assign bid = 1'b0;
  assign bresp = 2'b00;
  assign arready = !rst && !rvalid_q && ((lfsr & 'h700) != 0);
  assign rvalid = rvalid_q;
  assign rid = 1'b0;
  assign rdata = mem[araddr_q[15:6] + rbeat];
  assign rresp = 2'b00;
  assign rlast = rvalid_q && (rbeat == arlen_q);

  function automatic logic [511:0] apply_mask(
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

  always_ff @(posedge clk) begin
    if (rst) begin
      awaddr_q <= '0;
      awlen_q <= '0;
      wbeat <= '0;
      aw_active <= 1'b0;
      bvalid_q <= 1'b0;
      bdelay <= '0;
      araddr_q <= '0;
      arlen_q <= '0;
      rbeat <= '0;
      rvalid_q <= 1'b0;
      rdelay <= '0;
      lfsr <= SEED;
    end else begin
      lfsr <= lfsr * 32'h1665_2d5b + 32'h9e37_79b9;

      if (awvalid && awready) begin
        awaddr_q <= awaddr;
        awlen_q <= awlen;
        wbeat <= '0;
        aw_active <= 1'b1;
        if (awsize != 3'd6 || awburst != 2'b01)
          $fatal(1, "axi_beat_mem: expected 64-byte INCR write");
      end

      if (wvalid && wready) begin
        automatic int unsigned beat_index = awaddr_q[15:6] + wbeat;
        mem[beat_index] <= apply_mask(mem[beat_index], wdata, wstrb);
        if (wlast || wbeat == awlen_q) begin
          aw_active <= 1'b0;
          bdelay <= 3;
        end else begin
          wbeat <= wbeat + 1'b1;
        end
      end

      if (aw_active && !bvalid_q && bdelay == 0)
        ;
      else if (bdelay != 0) begin
        bdelay <= bdelay - 1'b1;
        if (bdelay == 1)
          bvalid_q <= 1'b1;
      end
      if (bvalid_q && bready)
        bvalid_q <= 1'b0;

      if (arvalid && arready) begin
        araddr_q <= araddr;
        arlen_q <= arlen;
        rbeat <= '0;
        rdelay <= 2;
        if (arsize != 3'd6 || arburst != 2'b01)
          $fatal(1, "axi_beat_mem: expected 64-byte INCR read");
      end

      if (rdelay != 0) begin
        rdelay <= rdelay - 1'b1;
        if (rdelay == 1)
          rvalid_q <= 1'b1;
      end
      if (rvalid_q && rready) begin
        if (rbeat == arlen_q)
          rvalid_q <= 1'b0;
        else
          rbeat <= rbeat + 1'b1;
      end
    end
  end
endmodule

module native_axi_driver #(
  parameter int CH = 0,
  parameter int OPS = 256,
  parameter int BEATS = 1024,
  parameter int SEED = 32'h1234_5678
) (
  input  logic clk,
  input  logic rst,
  input  logic n_cready,
  output logic n_cvalid,
  output logic n_cwe,
  output logic [24:0] n_caddr,
  input  logic n_wready,
  output logic n_wvalid,
  output logic [511:0] n_wdata,
  output logic [63:0] n_wmask,
  input  logic n_rvalid,
  input  logic [511:0] n_rdata,
  input  logic [15:0] n_wdone,
  input  logic n_err,
  output logic done,
  output int errors
);
  logic [511:0] shadow [BEATS];
  logic [31:0] lfsr;

  function automatic logic [31:0] next_rand;
    lfsr = lfsr * 32'h1665_2d5b + 32'h9e37_79b9;
    return lfsr;
  endfunction

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

  task automatic issue_command(input logic we, input logic [24:0] addr);
    int guard;
    begin
      @(negedge clk);
      n_cvalid = 1'b1;
      n_cwe = we;
      n_caddr = addr;
      guard = 0;
      while (!n_cready) begin
        @(posedge clk);
        if (++guard > 100000)
          $fatal(1, "native_axi_driver ch%0d command timeout", CH);
      end
      @(posedge clk);
      @(negedge clk);
      n_cvalid = 1'b0;
    end
  endtask

  task automatic issue_write_data(input logic [511:0] data, input logic [63:0] mask);
    int guard;
    begin
      @(negedge clk);
      n_wvalid = 1'b1;
      n_wdata = data;
      n_wmask = mask;
      guard = 0;
      while (!n_wready) begin
        @(posedge clk);
        if (++guard > 100000)
          $fatal(1, "native_axi_driver ch%0d write-data timeout", CH);
      end
      @(posedge clk);
      @(negedge clk);
      n_wvalid = 1'b0;
    end
  endtask

  initial begin
    logic [24:0] addr;
    logic [511:0] data;
    logic [63:0] mask;
    logic [15:0] wdone_base;
    int idx;

    n_cvalid = 1'b0;
    n_cwe = 1'b0;
    n_caddr = '0;
    n_wvalid = 1'b0;
    n_wdata = '0;
    n_wmask = '0;
    done = 1'b0;
    errors = 0;
    lfsr = SEED;
    for (int i = 0; i < BEATS; i++)
      shadow[i] = '0;

    wait (!rst);
    repeat (20) @(posedge clk);
    if (n_err)
      $fatal(1, "native_axi_driver ch%0d error after reset", CH);

    for (int op = 0; op < OPS; op++) begin
      idx = next_rand() % BEATS;
      addr = 25'(idx);
      for (int w = 0; w < 16; w++)
        data[w*32 +: 32] = next_rand();
      mask = (next_rand() & 3) == 0 ? {64{1'b1}} : {next_rand(), next_rand()};
      if (mask == '0)
        mask = 64'h1;

      wdone_base = n_wdone;
      fork
        issue_command(1'b1, addr);
        issue_write_data(data, mask);
      join
      shadow[idx] = merge_mask(shadow[idx], data, mask);

      while (n_wdone != (wdone_base + 16'd1)) begin
        @(posedge clk);
        if (n_err)
          $fatal(1, "native_axi_driver ch%0d write error op=%0d", CH, op);
      end

      issue_command(1'b0, addr);
      while (!n_rvalid) @(posedge clk);
      if (n_rdata !== shadow[idx]) begin
        $error("native_axi_driver ch%0d read mismatch op=%0d addr=%0d got=%h expected=%h",
               CH, op, idx, n_rdata, shadow[idx]);
        errors++;
      end
      @(posedge clk);
    end

    if (errors != 0)
      $fatal(1, "native_axi_driver ch%0d errors=%0d", CH, errors);
    $display("PASS native_axi_driver ch%0d ops=%0d", CH, OPS);
    done = 1'b1;
  end
endmodule

module tb_native_axi_dual;
  localparam int OPS = 256;

  logic clk;
  logic rst;
  logic [1:0] aclk;
  logic [1:0] arst;

  logic [1:0] n_cvalid;
  logic [1:0] n_cready;
  logic [1:0] n_cwe;
  logic [1:0][24:0] n_caddr;
  logic [1:0] n_wvalid;
  logic [1:0] n_wready;
  logic [1:0][511:0] n_wdata;
  logic [1:0][63:0] n_wmask;
  logic [1:0] n_rvalid;
  logic [1:0][511:0] n_rdata;
  logic [1:0][15:0] n_wdone;
  logic [1:0] n_err;

  logic [1:0][0:0] m_awid;
  logic [1:0][31:0] m_awaddr;
  logic [1:0][7:0] m_awlen;
  logic [1:0][2:0] m_awsize;
  logic [1:0][1:0] m_awburst;
  logic [1:0] m_awlock;
  logic [1:0][3:0] m_awcache;
  logic [1:0][2:0] m_awprot;
  logic [1:0][3:0] m_awqos;
  logic [1:0] m_awvalid;
  logic [1:0] m_awready;
  logic [1:0][511:0] m_wdata;
  logic [1:0][63:0] m_wstrb;
  logic [1:0] m_wlast;
  logic [1:0] m_wvalid;
  logic [1:0] m_wready;
  logic [1:0][0:0] m_bid;
  logic [1:0][1:0] m_bresp;
  logic [1:0] m_bvalid;
  logic [1:0] m_bready;
  logic [1:0][0:0] m_arid;
  logic [1:0][31:0] m_araddr;
  logic [1:0][7:0] m_arlen;
  logic [1:0][2:0] m_arsize;
  logic [1:0][1:0] m_arburst;
  logic [1:0] m_arlock;
  logic [1:0][3:0] m_arcache;
  logic [1:0][2:0] m_arprot;
  logic [1:0][3:0] m_arqos;
  logic [1:0] m_arvalid;
  logic [1:0] m_arready;
  logic [1:0][0:0] m_rid;
  logic [1:0][511:0] m_rdata;
  logic [1:0][1:0] m_rresp;
  logic [1:0] m_rlast;
  logic [1:0] m_rvalid;
  logic [1:0] m_rready;

  logic [1:0] done;

  always #5.0 clk = ~clk;
  always #1.6667 aclk[0] = ~aclk[0];
  always #2.0 aclk[1] = ~aclk[1];

  otpu_native_axi_sys #(
    .MAX_BURST(64),
    .CMD_DEPTH(64),
    .WD_DEPTH(64),
    .RD_DEPTH(128),
    .EVT_DEPTH(16),
    .COALESCE_WAIT(8),
    .IDW(1)
  ) dut (
    .clk(clk), .rst(rst),
    .n_cvalid(n_cvalid), .n_cready(n_cready), .n_cwe(n_cwe), .n_caddr(n_caddr),
    .n_wvalid(n_wvalid), .n_wready(n_wready), .n_wdata(n_wdata), .n_wmask(n_wmask),
    .n_rvalid(n_rvalid), .n_rdata(n_rdata), .n_wdone(n_wdone), .n_err(n_err),
    .aclk(aclk), .arst(arst),
    .m_awid(m_awid), .m_awaddr(m_awaddr), .m_awlen(m_awlen),
    .m_awsize(m_awsize), .m_awburst(m_awburst), .m_awlock(m_awlock),
    .m_awcache(m_awcache), .m_awprot(m_awprot), .m_awqos(m_awqos),
    .m_awvalid(m_awvalid), .m_awready(m_awready),
    .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
    .m_wvalid(m_wvalid), .m_wready(m_wready),
    .m_bid(m_bid), .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
    .m_arid(m_arid), .m_araddr(m_araddr), .m_arlen(m_arlen),
    .m_arsize(m_arsize), .m_arburst(m_arburst), .m_arlock(m_arlock),
    .m_arcache(m_arcache), .m_arprot(m_arprot), .m_arqos(m_arqos),
    .m_arvalid(m_arvalid), .m_arready(m_arready),
    .m_rid(m_rid), .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rlast(m_rlast),
    .m_rvalid(m_rvalid), .m_rready(m_rready)
  );

  for (genvar c = 0; c < 2; c++) begin : g_slave
    axi_beat_mem #(.SEED(32'h1000_0000 + c * 32'h2468_ace1)) slave (
      .clk(aclk[c]), .rst(arst[c]),
      .awvalid(m_awvalid[c]), .awready(m_awready[c]),
      .awaddr(m_awaddr[c]), .awlen(m_awlen[c]), .awsize(m_awsize[c]),
      .awburst(m_awburst[c]),
      .wvalid(m_wvalid[c]), .wready(m_wready[c]), .wdata(m_wdata[c]),
      .wstrb(m_wstrb[c]), .wlast(m_wlast[c]),
      .bvalid(m_bvalid[c]), .bready(m_bready[c]), .bid(m_bid[c]), .bresp(m_bresp[c]),
      .arvalid(m_arvalid[c]), .arready(m_arready[c]), .araddr(m_araddr[c]),
      .arlen(m_arlen[c]), .arsize(m_arsize[c]), .arburst(m_arburst[c]),
      .rvalid(m_rvalid[c]), .rready(m_rready[c]), .rid(m_rid[c]),
      .rdata(m_rdata[c]), .rresp(m_rresp[c]), .rlast(m_rlast[c])
    );
  end

  for (genvar c = 0; c < 2; c++) begin : g_driver
    native_axi_driver #(
      .CH(c), .OPS(OPS), .SEED(32'hc000_0000 + c * 32'h1020_3040)
    ) driver (
      .clk(clk), .rst(rst),
      .n_cready(n_cready[c]), .n_cvalid(n_cvalid[c]), .n_cwe(n_cwe[c]),
      .n_caddr(n_caddr[c]),
      .n_wready(n_wready[c]), .n_wvalid(n_wvalid[c]), .n_wdata(n_wdata[c]),
      .n_wmask(n_wmask[c]),
      .n_rvalid(n_rvalid[c]), .n_rdata(n_rdata[c]), .n_wdone(n_wdone[c]),
      .n_err(n_err[c]), .done(done[c])
    );
  end

  initial begin
    clk = 1'b0;
    aclk = '0;
    rst = 1'b1;
    arst = 2'b11;
    #300;
    arst = 2'b00;
    #100;
    rst = 1'b0;
  end

  initial begin
    #20_000_000;
    $fatal(1, "tb_native_axi_dual timeout");
  end

  initial begin
    wait (done == 2'b11);
    $display("PASS tb_native_axi_dual channels=2 ops_each=%0d clocks=300MHz,250MHz",
             OPS);
    $finish;
  end
endmodule

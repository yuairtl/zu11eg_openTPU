// Common-reset asynchronous FIFO for the ZU11EG native-to-AXI bridge.
//
// Vivado uses the vendor XPM implementation so the large 576/514-bit FIFOs
// infer block RAM and report_cdc can identify the CDC topology. Verilator uses
// the repository's behavioral FIFO behind reset synchronizers with the same
// externally visible contract.
module otpu_native_fifo #(
  parameter int W = 32,
  parameter int DEPTH = 16,
  parameter string MEMORY = "distributed"
) (
  input  logic         wclk,
  input  logic         wrst,
  input  logic         wvalid,
  output logic         wready,
  input  logic [W-1:0] wdata,
  input  logic         rclk,
  input  logic         rrst,
  output logic         rvalid,
  input  logic         rready,
  output logic [W-1:0] rdata
);
  // Either side's reset resets the complete FIFO. The vendor macro synchronizes
  // the common reset internally; the behavioral path below does the same.
  wire reset = wrst | rrst;

`ifndef SYNTHESIS
  initial if (MEMORY != "distributed" && MEMORY != "block")
    $fatal(1, "otpu_native_fifo: MEMORY must be distributed or block");
`endif

`ifdef SYNTHESIS
  logic        wr_rst_busy;
  logic        rd_rst_busy;
  logic        full;
  logic        empty;
  logic [W-1:0] dout;
  logic [0:0]  unused_almost_empty;
  logic [0:0]  unused_almost_full;
  logic [0:0]  unused_data_valid;
  logic [0:0]  unused_dbiterr;
  logic [0:0]  unused_overflow;
  logic [0:0]  unused_prog_empty;
  logic [0:0]  unused_prog_full;
  logic [0:0]  unused_rd_data_count;
  logic [0:0]  unused_sbiterr;
  logic [0:0]  unused_underflow;
  logic [0:0]  unused_wr_ack;
  logic [0:0]  unused_wr_data_count;

  xpm_fifo_async #(
    .CDC_SYNC_STAGES(2),
    .DOUT_RESET_VALUE("0"),
    .ECC_MODE("no_ecc"),
    .FIFO_MEMORY_TYPE(MEMORY),
    .FIFO_READ_LATENCY(0),
    .FIFO_WRITE_DEPTH(DEPTH),
    .FULL_RESET_VALUE(1),
    .PROG_EMPTY_THRESH(10),
    .PROG_FULL_THRESH(10),
    .RD_DATA_COUNT_WIDTH(1),
    .READ_DATA_WIDTH(W),
    .READ_MODE("fwft"),
    .RELATED_CLOCKS(0),
    .SIM_ASSERT_CHK(0),
    .USE_ADV_FEATURES("0000"),
    .WAKEUP_TIME(0),
    .WRITE_DATA_WIDTH(W),
    .WR_DATA_COUNT_WIDTH(1)
  ) u_xpm (
    .almost_empty(unused_almost_empty[0]),
    .almost_full(unused_almost_full[0]),
    .data_valid(unused_data_valid[0]),
    .dbiterr(unused_dbiterr[0]),
    .dout(dout),
    .empty(empty),
    .full(full),
    .overflow(unused_overflow[0]),
    .prog_empty(unused_prog_empty[0]),
    .prog_full(unused_prog_full[0]),
    .rd_data_count(unused_rd_data_count[0]),
    .rd_en(rvalid && rready),
    .rd_clk(rclk),
    .rd_rst_busy(rd_rst_busy),
    .rst(reset),
    .sbiterr(unused_sbiterr[0]),
    .sleep(1'b0),
    .underflow(unused_underflow[0]),
    .wr_ack(unused_wr_ack[0]),
    .wr_clk(wclk),
    .wr_data_count(unused_wr_data_count[0]),
    .wr_en(wready && wvalid),
    .wr_rst_busy(wr_rst_busy),
    .din(wdata),
    .injectdbiterr(1'b0),
    .injectsbiterr(1'b0)
  );

  assign wready = !reset && !wr_rst_busy && !full;
  assign rvalid = !reset && !rd_rst_busy && !empty;
  assign rdata = dout;
`else
  wire reset_n = ~reset;
  (* ASYNC_REG = "TRUE" *) logic w_rst_meta;
  (* ASYNC_REG = "TRUE" *) logic w_rst_sync;
  (* ASYNC_REG = "TRUE" *) logic r_rst_meta;
  (* ASYNC_REG = "TRUE" *) logic r_rst_sync;

  // Active-high local resets: assert asynchronously with either source and
  // deassert synchronously in each clock domain after both sources are clear.
  always_ff @(posedge wclk or negedge reset_n)
    if (!reset_n) {w_rst_meta, w_rst_sync} <= 2'b00;
    else {w_rst_meta, w_rst_sync} <= {1'b1, w_rst_meta};
  always_ff @(posedge rclk or negedge reset_n)
    if (!reset_n) {r_rst_meta, r_rst_sync} <= 2'b00;
    else {r_rst_meta, r_rst_sync} <= {1'b1, r_rst_meta};

  logic        b_wready;
  logic        b_rvalid;
  logic [W-1:0] b_rdata;
  logic        unused_wcommit;
  logic [$clog2(DEPTH):0] unused_wused;
  logic [$clog2(DEPTH):0] unused_rused;

  otpu_afifo #(.W(W), .DEPTH(DEPTH)) u_beh (
    .wclk(wclk), .wrst(!w_rst_sync), .wvalid(wvalid), .wready(b_wready),
    .wdata(wdata), .wslot('0), .wcommit(unused_wcommit),
    .wused(unused_wused),
    .rclk(rclk), .rrst(!r_rst_sync), .rvalid(b_rvalid), .rready(rready),
    .rdata(b_rdata), .rused(unused_rused)
  );

  assign wready = b_wready && w_rst_sync;
  assign rvalid = b_rvalid && r_rst_sync;
  assign rdata = b_rdata;
`endif
endmodule

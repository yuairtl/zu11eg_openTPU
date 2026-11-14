// Per-channel native 512-bit/64-byte command bridge to a MIG AXI4 slave.
//
// The native side runs in the openTPU Core clock. The AXI side runs in the MIG UI/AXI
// clock. Commands and write data cross through asynchronous FIFOs; read data and write
// completions cross back the other way. One burst is active at a time, which preserves native
// command order, makes read-after-write visibility unambiguous, and lets n_wdone advance only
// when the matching AXI B response returns.
//
// Adjacent same-direction commands are collected into one AXI INCR burst of 1..MAX_BURST
// 512-bit beats. A burst never crosses a 4 KiB boundary. COALESCE_WAIT gives a short stream of
// native commands time to accumulate before a partial burst is sealed.
//
// A reset in either clock domain resets the complete bridge, including both
// sides of every asynchronous FIFO. This keeps the gray pointers a single
// logical queue even when the PS and MIG reset trees deassert at different
// times.
module otpu_native_axi_ch #(
  parameter int MAX_BURST = 64,
  parameter int CMD_DEPTH = 64,
  parameter int WD_DEPTH  = 64,
  parameter int RD_DEPTH  = 128,
  parameter int EVT_DEPTH = 16,
  parameter int COALESCE_WAIT = 32,
  parameter int TIMEOUT_CYCLES = 1_000_000,
  parameter int IDW = 1,
  parameter logic [IDW-1:0] AXID = '0
) (
  // openTPU Core native side, clk/rst
  input  logic            clk,
  input  logic            rst,
  input  logic            n_cvalid,
  output logic            n_cready,
  input  logic            n_cwe,
  input  logic [24:0]     n_caddr,
  input  logic            n_wvalid,
  output logic            n_wready,
  input  logic [511:0]    n_wdata,
  input  logic [63:0]     n_wmask,   // 1 = write the byte
  output logic            n_rvalid,  // native read data has no backpressure
  output logic [511:0]    n_rdata,
  output logic [15:0]     n_wdone,   // B responses, modulo 2^16
  output logic            n_err,     // AXI response/protocol error, sticky until reset

  // MIG AXI4 master, aclk/arst
  input  logic            aclk,
  input  logic            arst,
  output logic [IDW-1:0]  m_awid,
  output logic [31:0]     m_awaddr,
  output logic [7:0]      m_awlen,
  output logic [2:0]      m_awsize,
  output logic [1:0]      m_awburst,
  output logic            m_awlock,
  output logic [3:0]      m_awcache,
  output logic [2:0]      m_awprot,
  output logic [3:0]      m_awqos,
  output logic            m_awvalid,
  input  logic            m_awready,
  output logic [511:0]    m_wdata,
  output logic [63:0]     m_wstrb,
  output logic            m_wlast,
  output logic            m_wvalid,
  input  logic            m_wready,
  input  logic [IDW-1:0]  m_bid,
  input  logic [1:0]      m_bresp,
  input  logic            m_bvalid,
  output logic            m_bready,
  output logic [IDW-1:0]  m_arid,
  output logic [31:0]     m_araddr,
  output logic [7:0]      m_arlen,
  output logic [2:0]      m_arsize,
  output logic [1:0]      m_arburst,
  output logic            m_arlock,
  output logic [3:0]      m_arcache,
  output logic [2:0]      m_arprot,
  output logic [3:0]      m_arqos,
  output logic            m_arvalid,
  input  logic            m_arready,
  input  logic [IDW-1:0]  m_rid,
  input  logic [511:0]    m_rdata,
  input  logic [1:0]      m_rresp,
  input  logic            m_rlast,
  input  logic            m_rvalid,
  output logic            m_rready
);
  localparam int CMD_W = 26;             // {write, 64-byte beat address}
  localparam int WD_W  = 576;            // {byte mask, data}
  localparam int RD_W  = 514;            // {response, data}
  localparam int EVT_W = 9;              // {error, write beats completed}
  localparam int CNT_W = $clog2(MAX_BURST + 1);
  localparam int BIDX_W = $clog2(MAX_BURST);
  localparam int TOW = $clog2(TIMEOUT_CYCLES + 1);

  initial begin
    if (MAX_BURST < 4 || MAX_BURST > 64)
      $fatal(1, "otpu_native_axi_ch: MAX_BURST must be 4..64");
    if (CMD_DEPTH < 16 || WD_DEPTH < 16 || RD_DEPTH < 16 || EVT_DEPTH < 16)
      $fatal(1, "otpu_native_axi_ch: FIFO depths must be at least 16 for XPM");
    if (TIMEOUT_CYCLES < 16)
      $fatal(1, "otpu_native_axi_ch: TIMEOUT_CYCLES must be at least 16");
    if ((CMD_DEPTH & (CMD_DEPTH - 1)) != 0 ||
        (WD_DEPTH & (WD_DEPTH - 1)) != 0 ||
        (RD_DEPTH & (RD_DEPTH - 1)) != 0 ||
        (EVT_DEPTH & (EVT_DEPTH - 1)) != 0)
      $fatal(1, "otpu_native_axi_ch: FIFO depths must be powers of two");
  end

  // ------------------------------------------------------------------ Core -> AXI
  logic cmd_wvalid, cmd_wready, cmd_rvalid, cmd_rready;
  logic [CMD_W-1:0] cmd_wdata, cmd_rdata;

  logic wd_wvalid, wd_wready, wd_rvalid, wd_rready;
  logic [WD_W-1:0] wd_wdata, wd_rdata;

  assign n_cready = cmd_wready;
  assign n_wready = wd_wready;
  assign cmd_wvalid = n_cvalid && !rst;
  assign cmd_wdata = {n_cwe, n_caddr};
  assign wd_wvalid = n_wvalid && !rst;
  assign wd_wdata = {n_wmask, n_wdata};

  otpu_native_fifo #(.W(CMD_W), .DEPTH(CMD_DEPTH), .MEMORY("distributed")) u_cmd (
    .wclk(clk), .wrst(rst), .wvalid(cmd_wvalid), .wready(cmd_wready),
    .wdata(cmd_wdata),
    .rclk(aclk), .rrst(arst), .rvalid(cmd_rvalid), .rready(cmd_rready),
    .rdata(cmd_rdata)
  );
  otpu_native_fifo #(.W(WD_W), .DEPTH(WD_DEPTH), .MEMORY("block")) u_wd (
    .wclk(clk), .wrst(rst), .wvalid(wd_wvalid), .wready(wd_wready),
    .wdata(wd_wdata),
    .rclk(aclk), .rrst(arst), .rvalid(wd_rvalid), .rready(wd_rready),
    .rdata(wd_rdata)
  );

  // ------------------------------------------------------------------ AXI -> Core
  logic rdf_wvalid, rdf_wready, rdf_rvalid, rdf_rready;
  logic [RD_W-1:0] rdf_wdata, rdf_rdata;

  logic evt_wvalid, evt_wready, evt_rvalid, evt_rready;
  logic [EVT_W-1:0] evt_wdata, evt_rdata;

  otpu_native_fifo #(.W(RD_W), .DEPTH(RD_DEPTH), .MEMORY("block")) u_rd (
    .wclk(aclk), .wrst(arst), .wvalid(rdf_wvalid), .wready(rdf_wready),
    .wdata(rdf_wdata),
    .rclk(clk), .rrst(rst), .rvalid(rdf_rvalid), .rready(rdf_rready),
    .rdata(rdf_rdata)
  );
  otpu_native_fifo #(.W(EVT_W), .DEPTH(EVT_DEPTH), .MEMORY("distributed")) u_evt (
    .wclk(aclk), .wrst(arst), .wvalid(evt_wvalid), .wready(evt_wready),
    .wdata(evt_wdata),
    .rclk(clk), .rrst(rst), .rvalid(evt_rvalid), .rready(evt_rready),
    .rdata(evt_rdata)
  );

  assign n_rvalid = rdf_rvalid;
  assign n_rdata = rdf_rdata[511:0];
  assign rdf_rready = 1'b1;  // the native read port itself has no backpressure
  assign evt_rready = 1'b1;

  // ------------------------------------------------------------------ AXI burst engine
  typedef enum logic [3:0] {
    ST_IDLE,
    ST_FILL,
    ST_WR_WAIT,
    ST_WR_AW,
    ST_WR_W,
    ST_WR_B,
    ST_RD_AR,
    ST_RD_R,
    ST_FAULT
  } state_t;

  state_t state, state_n;
  logic [25:0] abuf [MAX_BURST];
  logic [CNT_W-1:0] count, count_n;
  logic [CNT_W-1:0] beat, beat_n;
  logic [7:0] fill_wait, fill_wait_n;
  logic [TOW-1:0] stall_count, stall_count_n;
  logic axi_err;
  logic cmd_pop;
  logic progress;
  logic fault_reported, fault_event;

  logic cur_we;
  logic [24:0] cur_addr;
  assign cur_we = abuf[0][25];
  assign cur_addr = abuf[0][24:0];

  // The next native command extends the run only when it has the same direction, the next
  // 64-byte address, and the burst stays inside the current 4 KiB page.
  function automatic logic extends_run(
    input logic [CMD_W-1:0] first,
    input logic [CNT_W-1:0] n,
    input logic [CMD_W-1:0] nxt
  );
    logic [24:0] next_addr_f;
    next_addr_f = first[24:0] + 25'(n);
    extends_run = (nxt[25] == first[25]) &&
                  (nxt[24:0] == next_addr_f) &&
                  (next_addr_f[5:0] != 6'd0);
  endfunction

  assign m_awid = AXID;
  assign m_awaddr = {1'b0, cur_addr, 6'b0};
  assign m_awlen = 8'(count - 1'b1);
  assign m_awsize = 3'd6;       // 64 bytes
  assign m_awburst = 2'b01;     // INCR
  assign m_awlock = 1'b0;
  assign m_awcache = 4'b0011;
  assign m_awprot = 3'b000;
  assign m_awqos = 4'b0000;
  assign m_wdata = wd_rdata[511:0];
  assign m_wstrb = wd_rdata[575:512];
  assign m_wlast = (beat == count - 1'b1);

  assign m_arid = AXID;
  assign m_araddr = {1'b0, cur_addr, 6'b0};
  assign m_arlen = 8'(count - 1'b1);
  assign m_arsize = 3'd6;
  assign m_arburst = 2'b01;
  assign m_arlock = 1'b0;
  assign m_arcache = 4'b0011;
  assign m_arprot = 3'b000;
  assign m_arqos = 4'b0000;

  always_comb begin
    state_n = state;
    count_n = count;
    beat_n = beat;
    fill_wait_n = fill_wait;
    stall_count_n = stall_count;
    cmd_pop = 1'b0;
    progress = 1'b0;
    fault_event = 1'b0;
    wd_rready = 1'b0;
    rdf_wvalid = 1'b0;
    rdf_wdata = {2'b00, m_rdata};
    evt_wvalid = 1'b0;
    evt_wdata = {1'b0, 8'(count)};
    m_awvalid = 1'b0;
    m_wvalid = 1'b0;
    m_bready = 1'b0;
    m_arvalid = 1'b0;
    m_rready = 1'b0;

    case (state)
      ST_IDLE: begin
        count_n = '0;
        beat_n = '0;
        fill_wait_n = '0;
        if (!axi_err && cmd_rvalid) begin
          cmd_pop = 1'b1;
          count_n = CNT_W'(1);
          state_n = ST_FILL;
        end
      end

      ST_FILL: begin
        if (count >= CNT_W'(MAX_BURST))
          state_n = cur_we ? ST_WR_WAIT : ST_RD_AR;
        else if (cmd_rvalid) begin
          if (extends_run(abuf[0], count, cmd_rdata)) begin
            cmd_pop = 1'b1;
            count_n = count + 1'b1;
            fill_wait_n = '0;
          end else begin
            state_n = cur_we ? ST_WR_WAIT : ST_RD_AR;
          end
        end else begin
          if (fill_wait >= 8'(COALESCE_WAIT))
            state_n = cur_we ? ST_WR_WAIT : ST_RD_AR;
          else
            fill_wait_n = fill_wait + 1'b1;
        end
      end

      ST_WR_WAIT: begin
        // The AXI write may start once its first data beat has crossed into
        // this clock domain. Later beats are backpressured in ST_WR_W rather
        // than requiring the whole burst to be buffered before AW.
        if (wd_rvalid) begin
          progress = 1'b1;
          state_n = ST_WR_AW;
        end else
          state_n = ST_WR_WAIT;
      end

      ST_WR_AW: begin
        m_awvalid = !axi_err;
        if (m_awvalid && m_awready) begin
          progress = 1'b1;
          beat_n = '0;
          state_n = ST_WR_W;
        end
      end

      ST_WR_W: begin
        m_wvalid = wd_rvalid;
        if (m_wvalid && m_wready) begin
          progress = 1'b1;
          wd_rready = 1'b1;
          if (beat == count - 1'b1)
            state_n = ST_WR_B;
          else
            beat_n = beat + 1'b1;
        end
      end

      ST_WR_B: begin
        m_bready = evt_wready;
        if (m_bvalid && m_bready) begin
          progress = 1'b1;
          evt_wvalid = 1'b1;
          evt_wdata = {m_bresp != 2'b00, 8'(count)};
          state_n = ST_IDLE;
        end
      end

      ST_RD_AR: begin
        m_arvalid = !axi_err;
        if (m_arvalid && m_arready) begin
          progress = 1'b1;
          beat_n = '0;
          state_n = ST_RD_R;
        end
      end

      ST_RD_R: begin
        m_rready = rdf_wready;
        if (m_rvalid && m_rready) begin
          progress = 1'b1;
          rdf_wvalid = 1'b1;
          rdf_wdata = {m_rresp, m_rdata};
          if (beat == count - 1'b1)
            state_n = ST_IDLE;
          else
            beat_n = beat + 1'b1;
        end
      end

      ST_FAULT: begin
        fault_event = !fault_reported;
        evt_wvalid = fault_event;
        evt_wdata = {1'b1, 8'h00};
      end

      default: state_n = ST_IDLE;
    endcase

    // A stuck AXI handshake or missing response is a hard error. Hold here until reset rather
    // than allowing later native commands to overtake an unfinished transaction.
    if (state inside {ST_WR_WAIT, ST_WR_AW, ST_WR_W, ST_WR_B, ST_RD_AR, ST_RD_R}) begin
      if (progress) begin
        stall_count_n = '0;
      end else if (stall_count >= TOW'(TIMEOUT_CYCLES - 1)) begin
        state_n = ST_FAULT;
        fault_event = !fault_reported;
        evt_wvalid = fault_event;
        evt_wdata = {1'b1, 8'h00};
      end else begin
        stall_count_n = stall_count + 1'b1;
      end
    end else begin
      stall_count_n = '0;
    end
  end

  always_ff @(posedge aclk) begin
    if (arst) begin
      state <= ST_IDLE;
      count <= '0;
      beat <= '0;
      fill_wait <= '0;
      stall_count <= '0;
      axi_err <= 1'b0;
      fault_reported <= 1'b0;
    end else begin
      state <= state_n;
      count <= count_n;
      beat <= beat_n;
      fill_wait <= fill_wait_n;
      stall_count <= stall_count_n;

      // Store the command selected by the combinational fill logic. The async FIFO supplies
      // first-word-fall-through rdata, so this also covers the first command from ST_IDLE.
      if (cmd_pop) begin
        if (state == ST_IDLE)
          abuf[0] <= cmd_rdata;
        else
          abuf[count[BIDX_W-1:0]] <= cmd_rdata;
      end

      if (rdf_wvalid && m_rresp != 2'b00)
        axi_err <= 1'b1;
      if (state == ST_WR_B && m_bvalid && m_bready && m_bresp != 2'b00)
        axi_err <= 1'b1;
      if (m_bvalid && (m_bid != AXID))
        axi_err <= 1'b1;
      if (m_rvalid && (m_rid != AXID))
        axi_err <= 1'b1;
      if (fault_event && evt_wready)
        fault_reported <= 1'b1;
      if (fault_event)
        axi_err <= 1'b1;

      // Unexpected RLAST is a protocol error. On the expected last beat, hold the engine at
      // IDLE until the next command run has been collected.
      if (state == ST_RD_R && m_rvalid && m_rready &&
          (m_rlast != (beat == count - 1'b1)))
        axi_err <= 1'b1;
    end
  end

  // make command-FIFO pop and abuf write use exactly the same selected head
  assign cmd_rready = cmd_pop;

  // Error and write-completion crossing into the Core clock.
  (* ASYNC_REG = "TRUE" *) logic [1:0] mig_rst_sync;
  logic mig_reset_armed;
  always_ff @(posedge clk) begin
    if (rst) begin
      n_wdone <= '0;
      n_err <= 1'b0;
      mig_rst_sync <= 2'b00;
      mig_reset_armed <= 1'b0;
    end else begin
      mig_rst_sync <= {mig_rst_sync[0], arst};
      if (!mig_rst_sync[1])
        mig_reset_armed <= 1'b1;
      else if (mig_reset_armed)
        n_err <= 1'b1;
      if (evt_rvalid) begin
        n_wdone <= n_wdone + 16'(evt_rdata[7:0]);
        if (evt_rdata[8])
          n_err <= 1'b1;
      end
      if (rdf_rvalid && rdf_rdata[513:512] != 2'b00)
        n_err <= 1'b1;
    end
  end

endmodule

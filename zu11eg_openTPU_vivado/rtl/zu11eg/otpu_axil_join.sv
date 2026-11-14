// Standards-compliant AXI4-Lite write-channel join.
//
// The upstream openTPU control block assumes AWVALID and WVALID arrive in the
// same cycle. AXI4-Lite does not guarantee that, and the PS HPM0 interconnect
// may buffer the channels independently. This adapter captures each channel
// separately, presents them together to the existing slave, and holds the
// response until the master accepts it.
module otpu_axil_join #(
  parameter int AW = 12
) (
  input  logic          clk,
  input  logic          rst,

  input  logic [AW-1:0] s_awaddr,
  input  logic          s_awvalid,
  output logic          s_awready,
  input  logic [31:0]   s_wdata,
  input  logic [3:0]    s_wstrb,
  input  logic          s_wvalid,
  output logic          s_wready,
  output logic [1:0]    s_bresp,
  output logic          s_bvalid,
  input  logic          s_bready,
  input  logic [AW-1:0] s_araddr,
  input  logic          s_arvalid,
  output logic          s_arready,
  output logic [31:0]   s_rdata,
  output logic [1:0]    s_rresp,
  output logic          s_rvalid,
  input  logic          s_rready,

  output logic [AW-1:0] m_awaddr,
  output logic          m_awvalid,
  input  logic          m_awready,
  output logic [31:0]   m_wdata,
  output logic [3:0]    m_wstrb,
  output logic          m_wvalid,
  input  logic          m_wready,
  input  logic [1:0]    m_bresp,
  input  logic          m_bvalid,
  output logic          m_bready,
  output logic [AW-1:0] m_araddr,
  output logic          m_arvalid,
  input  logic          m_arready,
  input  logic [31:0]   m_rdata,
  input  logic [1:0]    m_rresp,
  input  logic          m_rvalid,
  output logic          m_rready
);
  logic [AW-1:0] aw_addr_q;
  logic [31:0]   w_data_q;
  logic [3:0]    w_strb_q;
  logic          aw_pending, w_pending, joined, write_wait, b_pending;
  logic [1:0]    bresp_q;

  wire can_accept = !rst && !write_wait && !b_pending;
  assign s_awready = can_accept && !aw_pending;
  assign s_wready  = can_accept && !w_pending;

  assign m_awaddr  = aw_addr_q;
  assign m_awvalid = !rst && aw_pending && (w_pending || joined);
  assign m_wdata   = w_data_q;
  assign m_wstrb   = w_strb_q;
  assign m_wvalid  = !rst && w_pending && (aw_pending || joined);

  assign s_bvalid = b_pending && !rst;
  assign s_bresp  = bresp_q;
  assign m_bready = !b_pending && !rst;

  // Read requests/responses do not share state with the write join.
  assign m_araddr  = s_araddr;
  assign m_arvalid = s_arvalid && !rst;
  assign s_arready = m_arready;
  assign s_rdata   = m_rdata;
  assign s_rresp   = m_rresp;
  assign s_rvalid  = m_rvalid && !rst;
  assign m_rready  = s_rready;

  always_ff @(posedge clk) begin
    if (rst) begin
      aw_pending <= 1'b0;
      w_pending <= 1'b0;
      joined <= 1'b0;
      write_wait <= 1'b0;
      b_pending <= 1'b0;
      bresp_q <= 2'b00;
    end else begin
      if (s_awvalid && s_awready) begin
        aw_addr_q <= s_awaddr;
        aw_pending <= 1'b1;
      end
      if (s_wvalid && s_wready) begin
        w_data_q <= s_wdata;
        w_strb_q <= s_wstrb;
        w_pending <= 1'b1;
      end
      if (aw_pending && w_pending) joined <= 1'b1;
      if (m_awvalid && m_awready) aw_pending <= 1'b0;
      if (m_wvalid && m_wready) w_pending <= 1'b0;
      if ((m_awvalid && m_awready) || (m_wvalid && m_wready))
        write_wait <= 1'b1;
      if (!aw_pending && !w_pending) joined <= 1'b0;
      if (m_bvalid && m_bready) begin
        write_wait <= 1'b0;
        b_pending <= 1'b1;
        bresp_q <= m_bresp;
      end
      if (b_pending && s_bready)
        b_pending <= 1'b0;
    end
  end
endmodule

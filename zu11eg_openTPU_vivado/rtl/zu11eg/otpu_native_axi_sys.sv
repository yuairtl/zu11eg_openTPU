// Two independent openTPU native-to-MIG-AXI channels.
//
// The Core clock is shared. Each channel has its own MIG AXI clock/reset so the two DDR4
// controllers may use independent MMCM outputs while retaining independent address windows.
// SmartConnect and the PS DataMover/CDMA connect to the two AXI masters outside this wrapper.
module otpu_native_axi_sys #(
  parameter int MAX_BURST = 64,
  parameter int CMD_DEPTH = 64,
  parameter int WD_DEPTH  = 64,
  parameter int RD_DEPTH  = 128,
  parameter int EVT_DEPTH = 16,
  parameter int COALESCE_WAIT = 32,
  parameter int TIMEOUT_CYCLES = 1_000_000,
  parameter int IDW = 1
) (
  // Core native interfaces
  input  logic              clk,
  input  logic              rst,
  input  logic [1:0]        n_cvalid,
  output logic [1:0]        n_cready,
  input  logic [1:0]        n_cwe,
  input  logic [1:0][24:0]  n_caddr,
  input  logic [1:0]        n_wvalid,
  output logic [1:0]        n_wready,
  input  logic [1:0][511:0] n_wdata,
  input  logic [1:0][63:0]  n_wmask,
  output logic [1:0]        n_rvalid,
  output logic [1:0][511:0] n_rdata,
  output logic [1:0][15:0]  n_wdone,
  output logic [1:0]        n_err,

  // One MIG AXI slave per DDR channel
  input  logic [1:0]              aclk,
  input  logic [1:0]              arst,
  output logic [1:0][IDW-1:0]     m_awid,
  output logic [1:0][31:0]        m_awaddr,
  output logic [1:0][7:0]         m_awlen,
  output logic [1:0][2:0]         m_awsize,
  output logic [1:0][1:0]         m_awburst,
  output logic [1:0]              m_awlock,
  output logic [1:0][3:0]         m_awcache,
  output logic [1:0][2:0]         m_awprot,
  output logic [1:0][3:0]         m_awqos,
  output logic [1:0]              m_awvalid,
  input  logic [1:0]              m_awready,
  output logic [1:0][511:0]       m_wdata,
  output logic [1:0][63:0]        m_wstrb,
  output logic [1:0]              m_wlast,
  output logic [1:0]              m_wvalid,
  input  logic [1:0]              m_wready,
  input  logic [1:0][IDW-1:0]     m_bid,
  input  logic [1:0][1:0]         m_bresp,
  input  logic [1:0]              m_bvalid,
  output logic [1:0]              m_bready,
  output logic [1:0][IDW-1:0]     m_arid,
  output logic [1:0][31:0]        m_araddr,
  output logic [1:0][7:0]         m_arlen,
  output logic [1:0][2:0]         m_arsize,
  output logic [1:0][1:0]         m_arburst,
  output logic [1:0]              m_arlock,
  output logic [1:0][3:0]         m_arcache,
  output logic [1:0][2:0]         m_arprot,
  output logic [1:0][3:0]         m_arqos,
  output logic [1:0]              m_arvalid,
  input  logic [1:0]              m_arready,
  input  logic [1:0][IDW-1:0]     m_rid,
  input  logic [1:0][511:0]       m_rdata,
  input  logic [1:0][1:0]         m_rresp,
  input  logic [1:0]              m_rlast,
  input  logic [1:0]              m_rvalid,
  output logic [1:0]              m_rready
);
  for (genvar c = 0; c < 2; c++) begin : g_ch
    otpu_native_axi_ch #(
      .MAX_BURST(MAX_BURST),
      .CMD_DEPTH(CMD_DEPTH),
      .WD_DEPTH(WD_DEPTH),
      .RD_DEPTH(RD_DEPTH),
      .EVT_DEPTH(EVT_DEPTH),
      .COALESCE_WAIT(COALESCE_WAIT),
      .TIMEOUT_CYCLES(TIMEOUT_CYCLES),
      .IDW(IDW),
      .AXID('0)
    ) u_ch (
      .clk(clk), .rst(rst),
      .n_cvalid(n_cvalid[c]), .n_cready(n_cready[c]), .n_cwe(n_cwe[c]),
      .n_caddr(n_caddr[c]),
      .n_wvalid(n_wvalid[c]), .n_wready(n_wready[c]), .n_wdata(n_wdata[c]),
      .n_wmask(n_wmask[c]),
      .n_rvalid(n_rvalid[c]), .n_rdata(n_rdata[c]),
      .n_wdone(n_wdone[c]), .n_err(n_err[c]),
      .aclk(aclk[c]), .arst(arst[c]),
      .m_awid(m_awid[c]), .m_awaddr(m_awaddr[c]), .m_awlen(m_awlen[c]),
      .m_awsize(m_awsize[c]), .m_awburst(m_awburst[c]), .m_awlock(m_awlock[c]),
      .m_awcache(m_awcache[c]), .m_awprot(m_awprot[c]), .m_awqos(m_awqos[c]),
      .m_awvalid(m_awvalid[c]), .m_awready(m_awready[c]),
      .m_wdata(m_wdata[c]), .m_wstrb(m_wstrb[c]), .m_wlast(m_wlast[c]),
      .m_wvalid(m_wvalid[c]), .m_wready(m_wready[c]),
      .m_bid(m_bid[c]), .m_bresp(m_bresp[c]), .m_bvalid(m_bvalid[c]),
      .m_bready(m_bready[c]),
      .m_arid(m_arid[c]), .m_araddr(m_araddr[c]), .m_arlen(m_arlen[c]),
      .m_arsize(m_arsize[c]), .m_arburst(m_arburst[c]), .m_arlock(m_arlock[c]),
      .m_arcache(m_arcache[c]), .m_arprot(m_arprot[c]), .m_arqos(m_arqos[c]),
      .m_arvalid(m_arvalid[c]), .m_arready(m_arready[c]),
      .m_rid(m_rid[c]), .m_rdata(m_rdata[c]), .m_rresp(m_rresp[c]),
      .m_rlast(m_rlast[c]), .m_rvalid(m_rvalid[c]), .m_rready(m_rready[c])
    );
  end
endmodule

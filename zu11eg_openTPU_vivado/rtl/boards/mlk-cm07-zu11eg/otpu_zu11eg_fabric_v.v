// Generated from otpu_zu11eg_fabric.sv. Do not edit by hand.
module otpu_zu11eg_fabric_v (
  // Core clock and the 2x TMEM pump clock.
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 core_clk CLK" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME core_clk,ASSOCIATED_BUSIF S_AXI_CTRL:S_AXI_HOST:M_AXI_HOST0:M_AXI_HOST1,ASSOCIATED_RESET core_rstn,FREQ_HZ 100000000" *)
  input  wire core_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 core_clk_f CLK" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME core_clk_f,FREQ_HZ 200000000" *)
  input  wire core_clk_f,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 core_rstn RST" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME core_rstn,POLARITY ACTIVE_LOW" *)
  input  wire core_rstn,

  // Independent MIG AXI clocks/resets.
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 mig0_clk CLK" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME mig0_clk,ASSOCIATED_BUSIF M_AXI_CORE0,ASSOCIATED_RESET mig0_rst,FREQ_HZ 300000000" *)
  input  wire mig0_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 mig0_rst RST" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME mig0_rst,POLARITY ACTIVE_HIGH" *)
  input  wire mig0_rst,
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 mig1_clk CLK" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME mig1_clk,ASSOCIATED_BUSIF M_AXI_CORE1,ASSOCIATED_RESET mig1_rst,FREQ_HZ 300000000" *)
  input  wire mig1_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 mig1_rst RST" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME mig1_rst,POLARITY ACTIVE_HIGH" *)
  input  wire mig1_rst,

  input  wire [1:0] calib,
  output wire dci_locked,

  // AXI-Lite control from PS HPM0.
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL AWADDR" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI_CTRL,PROTOCOL AXI4LITE,DATA_WIDTH 32,ADDR_WIDTH 12,READ_WRITE_MODE READ_WRITE,HAS_BURST 0,HAS_LOCK 0,HAS_CACHE 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 1" *)
  input  wire [11:0] s_axi_ctrl_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL AWVALID" *)
  input  wire s_axi_ctrl_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL AWREADY" *)
  output wire s_axi_ctrl_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL WDATA" *)
  input  wire [31:0] s_axi_ctrl_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL WSTRB" *)
  input  wire [3:0] s_axi_ctrl_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL WVALID" *)
  input  wire s_axi_ctrl_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL WREADY" *)
  output wire s_axi_ctrl_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL BRESP" *)
  output wire [1:0] s_axi_ctrl_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL BVALID" *)
  output wire s_axi_ctrl_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL BREADY" *)
  input  wire s_axi_ctrl_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL ARADDR" *)
  input  wire [11:0] s_axi_ctrl_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL ARVALID" *)
  input  wire s_axi_ctrl_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL ARREADY" *)
  output wire s_axi_ctrl_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL RDATA" *)
  output wire [31:0] s_axi_ctrl_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL RRESP" *)
  output wire [1:0] s_axi_ctrl_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL RVALID" *)
  output wire s_axi_ctrl_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL RREADY" *)
  input  wire s_axi_ctrl_rready,

  // AXI4 host data from the merged H2C/C2H DMA path. The CDMA adds the
  // 0x8_0000_0000 PL aperture; only the low 32 bits select the openTPU window.
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWADDR" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI_HOST,PROTOCOL AXI4,DATA_WIDTH 128,ADDR_WIDTH 64,ID_WIDTH 1,READ_WRITE_MODE READ_WRITE,HAS_BURST 1,HAS_LOCK 0,HAS_CACHE 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 1,SUPPORTS_NARROW_BURST 0" *)
  input  wire [63:0] s_axi_host_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWID" *)
  input  wire [0:0] s_axi_host_awid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWLEN" *)
  input  wire [7:0] s_axi_host_awlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWSIZE" *)
  input  wire [2:0] s_axi_host_awsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWBURST" *)
  input  wire [1:0] s_axi_host_awburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWVALID" *)
  input  wire s_axi_host_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWREADY" *)
  output wire s_axi_host_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST WDATA" *)
  input  wire [127:0] s_axi_host_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST WSTRB" *)
  input  wire [15:0] s_axi_host_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST WLAST" *)
  input  wire s_axi_host_wlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST WVALID" *)
  input  wire s_axi_host_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST WREADY" *)
  output wire s_axi_host_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST BID" *)
  output wire [0:0] s_axi_host_bid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST BRESP" *)
  output wire [1:0] s_axi_host_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST BVALID" *)
  output wire s_axi_host_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST BREADY" *)
  input  wire s_axi_host_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARADDR" *)
  input  wire [63:0] s_axi_host_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARID" *)
  input  wire [0:0] s_axi_host_arid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARLEN" *)
  input  wire [7:0] s_axi_host_arlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARSIZE" *)
  input  wire [2:0] s_axi_host_arsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARBURST" *)
  input  wire [1:0] s_axi_host_arburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARVALID" *)
  input  wire s_axi_host_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARREADY" *)
  output wire s_axi_host_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST RID" *)
  output wire [0:0] s_axi_host_rid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST RDATA" *)
  output wire [127:0] s_axi_host_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST RRESP" *)
  output wire [1:0] s_axi_host_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST RLAST" *)
  output wire s_axi_host_rlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST RVALID" *)
  output wire s_axi_host_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST RREADY" *)
  input  wire s_axi_host_rready,

  // Per-channel AXI masters into the MIG fabric.
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWADDR" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI_HOST0,PROTOCOL AXI4,DATA_WIDTH 128,ADDR_WIDTH 32,ID_WIDTH 1,READ_WRITE_MODE READ_WRITE,HAS_BURST 1,HAS_LOCK 0,HAS_CACHE 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 1,SUPPORTS_NARROW_BURST 0" *)
  output wire [31:0] m_axi_host0_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWID" *)
  output wire [0:0] m_axi_host0_awid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWLEN" *)
  output wire [7:0] m_axi_host0_awlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWSIZE" *)
  output wire [2:0] m_axi_host0_awsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWBURST" *)
  output wire [1:0] m_axi_host0_awburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWVALID" *)
  output wire m_axi_host0_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWREADY" *)
  input wire m_axi_host0_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 WDATA" *)
  output wire [127:0] m_axi_host0_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 WSTRB" *)
  output wire [15:0] m_axi_host0_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 WLAST" *)
  output wire m_axi_host0_wlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 WVALID" *)
  output wire m_axi_host0_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 WREADY" *)
  input wire m_axi_host0_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 BID" *)
  input wire [0:0] m_axi_host0_bid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 BRESP" *)
  input wire [1:0] m_axi_host0_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 BVALID" *)
  input wire m_axi_host0_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 BREADY" *)
  output wire m_axi_host0_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARADDR" *)
  output wire [31:0] m_axi_host0_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARID" *)
  output wire [0:0] m_axi_host0_arid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARLEN" *)
  output wire [7:0] m_axi_host0_arlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARSIZE" *)
  output wire [2:0] m_axi_host0_arsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARBURST" *)
  output wire [1:0] m_axi_host0_arburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARVALID" *)
  output wire m_axi_host0_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARREADY" *)
  input wire m_axi_host0_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 RID" *)
  input wire [0:0] m_axi_host0_rid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 RDATA" *)
  input wire [127:0] m_axi_host0_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 RRESP" *)
  input wire [1:0] m_axi_host0_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 RLAST" *)
  input wire m_axi_host0_rlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 RVALID" *)
  input wire m_axi_host0_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 RREADY" *)
  output wire m_axi_host0_rready,

  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWADDR" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI_HOST1,PROTOCOL AXI4,DATA_WIDTH 128,ADDR_WIDTH 32,ID_WIDTH 1,READ_WRITE_MODE READ_WRITE,HAS_BURST 1,HAS_LOCK 0,HAS_CACHE 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 1,SUPPORTS_NARROW_BURST 0" *)
  output wire [31:0] m_axi_host1_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWID" *)
  output wire [0:0] m_axi_host1_awid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWLEN" *)
  output wire [7:0] m_axi_host1_awlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWSIZE" *)
  output wire [2:0] m_axi_host1_awsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWBURST" *)
  output wire [1:0] m_axi_host1_awburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWVALID" *)
  output wire m_axi_host1_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWREADY" *)
  input wire m_axi_host1_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 WDATA" *)
  output wire [127:0] m_axi_host1_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 WSTRB" *)
  output wire [15:0] m_axi_host1_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 WLAST" *)
  output wire m_axi_host1_wlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 WVALID" *)
  output wire m_axi_host1_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 WREADY" *)
  input wire m_axi_host1_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 BID" *)
  input wire [0:0] m_axi_host1_bid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 BRESP" *)
  input wire [1:0] m_axi_host1_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 BVALID" *)
  input wire m_axi_host1_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 BREADY" *)
  output wire m_axi_host1_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARADDR" *)
  output wire [31:0] m_axi_host1_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARID" *)
  output wire [0:0] m_axi_host1_arid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARLEN" *)
  output wire [7:0] m_axi_host1_arlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARSIZE" *)
  output wire [2:0] m_axi_host1_arsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARBURST" *)
  output wire [1:0] m_axi_host1_arburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARVALID" *)
  output wire m_axi_host1_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARREADY" *)
  input wire m_axi_host1_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 RID" *)
  input wire [0:0] m_axi_host1_rid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 RDATA" *)
  input wire [127:0] m_axi_host1_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 RRESP" *)
  input wire [1:0] m_axi_host1_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 RLAST" *)
  input wire m_axi_host1_rlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 RVALID" *)
  input wire m_axi_host1_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 RREADY" *)
  output wire m_axi_host1_rready,

  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWADDR" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI_CORE0,PROTOCOL AXI4,DATA_WIDTH 512,ADDR_WIDTH 32,ID_WIDTH 1,READ_WRITE_MODE READ_WRITE,HAS_BURST 1,HAS_LOCK 0,HAS_CACHE 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 1,SUPPORTS_NARROW_BURST 0" *)
  output wire [31:0] m_axi_core0_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWID" *)
  output wire m_axi_core0_awid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWLEN" *)
  output wire [7:0] m_axi_core0_awlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWSIZE" *)
  output wire [2:0] m_axi_core0_awsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWBURST" *)
  output wire [1:0] m_axi_core0_awburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWVALID" *)
  output wire m_axi_core0_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWREADY" *)
  input wire m_axi_core0_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 WDATA" *)
  output wire [511:0] m_axi_core0_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 WSTRB" *)
  output wire [63:0] m_axi_core0_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 WLAST" *)
  output wire m_axi_core0_wlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 WVALID" *)
  output wire m_axi_core0_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 WREADY" *)
  input wire m_axi_core0_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 BID" *)
  input wire m_axi_core0_bid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 BRESP" *)
  input wire [1:0] m_axi_core0_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 BVALID" *)
  input wire m_axi_core0_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 BREADY" *)
  output wire m_axi_core0_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARADDR" *)
  output wire [31:0] m_axi_core0_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARID" *)
  output wire m_axi_core0_arid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARLEN" *)
  output wire [7:0] m_axi_core0_arlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARSIZE" *)
  output wire [2:0] m_axi_core0_arsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARBURST" *)
  output wire [1:0] m_axi_core0_arburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARVALID" *)
  output wire m_axi_core0_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARREADY" *)
  input wire m_axi_core0_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 RID" *)
  input wire m_axi_core0_rid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 RDATA" *)
  input wire [511:0] m_axi_core0_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 RRESP" *)
  input wire [1:0] m_axi_core0_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 RLAST" *)
  input wire m_axi_core0_rlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 RVALID" *)
  input wire m_axi_core0_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 RREADY" *)
  output wire m_axi_core0_rready,

  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWADDR" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI_CORE1,PROTOCOL AXI4,DATA_WIDTH 512,ADDR_WIDTH 32,ID_WIDTH 1,READ_WRITE_MODE READ_WRITE,HAS_BURST 1,HAS_LOCK 0,HAS_CACHE 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 1,SUPPORTS_NARROW_BURST 0" *)
  output wire [31:0] m_axi_core1_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWID" *)
  output wire m_axi_core1_awid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWLEN" *)
  output wire [7:0] m_axi_core1_awlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWSIZE" *)
  output wire [2:0] m_axi_core1_awsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWBURST" *)
  output wire [1:0] m_axi_core1_awburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWVALID" *)
  output wire m_axi_core1_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWREADY" *)
  input wire m_axi_core1_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 WDATA" *)
  output wire [511:0] m_axi_core1_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 WSTRB" *)
  output wire [63:0] m_axi_core1_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 WLAST" *)
  output wire m_axi_core1_wlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 WVALID" *)
  output wire m_axi_core1_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 WREADY" *)
  input wire m_axi_core1_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 BID" *)
  input wire m_axi_core1_bid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 BRESP" *)
  input wire [1:0] m_axi_core1_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 BVALID" *)
  input wire m_axi_core1_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 BREADY" *)
  output wire m_axi_core1_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARADDR" *)
  output wire [31:0] m_axi_core1_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARID" *)
  output wire m_axi_core1_arid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARLEN" *)
  output wire [7:0] m_axi_core1_arlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARSIZE" *)
  output wire [2:0] m_axi_core1_arsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARBURST" *)
  output wire [1:0] m_axi_core1_arburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARVALID" *)
  output wire m_axi_core1_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARREADY" *)
  input wire m_axi_core1_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 RID" *)
  input wire m_axi_core1_rid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 RDATA" *)
  input wire [511:0] m_axi_core1_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 RRESP" *)
  input wire [1:0] m_axi_core1_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 RLAST" *)
  input wire m_axi_core1_rlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 RVALID" *)
  input wire m_axi_core1_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 RREADY" *)
  output wire m_axi_core1_rready
);

  otpu_zu11eg_fabric u_otpu_zu11eg_fabric (
    .core_clk(core_clk),
    .core_clk_f(core_clk_f),
    .core_rstn(core_rstn),
    .mig0_clk(mig0_clk),
    .mig0_rst(mig0_rst),
    .mig1_clk(mig1_clk),
    .mig1_rst(mig1_rst),
    .calib(calib),
    .dci_locked(dci_locked),
    .s_axi_ctrl_awaddr(s_axi_ctrl_awaddr),
    .s_axi_ctrl_awvalid(s_axi_ctrl_awvalid),
    .s_axi_ctrl_awready(s_axi_ctrl_awready),
    .s_axi_ctrl_wdata(s_axi_ctrl_wdata),
    .s_axi_ctrl_wstrb(s_axi_ctrl_wstrb),
    .s_axi_ctrl_wvalid(s_axi_ctrl_wvalid),
    .s_axi_ctrl_wready(s_axi_ctrl_wready),
    .s_axi_ctrl_bresp(s_axi_ctrl_bresp),
    .s_axi_ctrl_bvalid(s_axi_ctrl_bvalid),
    .s_axi_ctrl_bready(s_axi_ctrl_bready),
    .s_axi_ctrl_araddr(s_axi_ctrl_araddr),
    .s_axi_ctrl_arvalid(s_axi_ctrl_arvalid),
    .s_axi_ctrl_arready(s_axi_ctrl_arready),
    .s_axi_ctrl_rdata(s_axi_ctrl_rdata),
    .s_axi_ctrl_rresp(s_axi_ctrl_rresp),
    .s_axi_ctrl_rvalid(s_axi_ctrl_rvalid),
    .s_axi_ctrl_rready(s_axi_ctrl_rready),
    .s_axi_host_awaddr(s_axi_host_awaddr),
    .s_axi_host_awid(s_axi_host_awid),
    .s_axi_host_awlen(s_axi_host_awlen),
    .s_axi_host_awsize(s_axi_host_awsize),
    .s_axi_host_awburst(s_axi_host_awburst),
    .s_axi_host_awvalid(s_axi_host_awvalid),
    .s_axi_host_awready(s_axi_host_awready),
    .s_axi_host_wdata(s_axi_host_wdata),
    .s_axi_host_wstrb(s_axi_host_wstrb),
    .s_axi_host_wlast(s_axi_host_wlast),
    .s_axi_host_wvalid(s_axi_host_wvalid),
    .s_axi_host_wready(s_axi_host_wready),
    .s_axi_host_bid(s_axi_host_bid),
    .s_axi_host_bresp(s_axi_host_bresp),
    .s_axi_host_bvalid(s_axi_host_bvalid),
    .s_axi_host_bready(s_axi_host_bready),
    .s_axi_host_araddr(s_axi_host_araddr),
    .s_axi_host_arid(s_axi_host_arid),
    .s_axi_host_arlen(s_axi_host_arlen),
    .s_axi_host_arsize(s_axi_host_arsize),
    .s_axi_host_arburst(s_axi_host_arburst),
    .s_axi_host_arvalid(s_axi_host_arvalid),
    .s_axi_host_arready(s_axi_host_arready),
    .s_axi_host_rid(s_axi_host_rid),
    .s_axi_host_rdata(s_axi_host_rdata),
    .s_axi_host_rresp(s_axi_host_rresp),
    .s_axi_host_rlast(s_axi_host_rlast),
    .s_axi_host_rvalid(s_axi_host_rvalid),
    .s_axi_host_rready(s_axi_host_rready),
    .m_axi_host0_awaddr(m_axi_host0_awaddr),
    .m_axi_host0_awid(m_axi_host0_awid),
    .m_axi_host0_awlen(m_axi_host0_awlen),
    .m_axi_host0_awsize(m_axi_host0_awsize),
    .m_axi_host0_awburst(m_axi_host0_awburst),
    .m_axi_host0_awvalid(m_axi_host0_awvalid),
    .m_axi_host0_awready(m_axi_host0_awready),
    .m_axi_host0_wdata(m_axi_host0_wdata),
    .m_axi_host0_wstrb(m_axi_host0_wstrb),
    .m_axi_host0_wlast(m_axi_host0_wlast),
    .m_axi_host0_wvalid(m_axi_host0_wvalid),
    .m_axi_host0_wready(m_axi_host0_wready),
    .m_axi_host0_bid(m_axi_host0_bid),
    .m_axi_host0_bresp(m_axi_host0_bresp),
    .m_axi_host0_bvalid(m_axi_host0_bvalid),
    .m_axi_host0_bready(m_axi_host0_bready),
    .m_axi_host0_araddr(m_axi_host0_araddr),
    .m_axi_host0_arid(m_axi_host0_arid),
    .m_axi_host0_arlen(m_axi_host0_arlen),
    .m_axi_host0_arsize(m_axi_host0_arsize),
    .m_axi_host0_arburst(m_axi_host0_arburst),
    .m_axi_host0_arvalid(m_axi_host0_arvalid),
    .m_axi_host0_arready(m_axi_host0_arready),
    .m_axi_host0_rid(m_axi_host0_rid),
    .m_axi_host0_rdata(m_axi_host0_rdata),
    .m_axi_host0_rresp(m_axi_host0_rresp),
    .m_axi_host0_rlast(m_axi_host0_rlast),
    .m_axi_host0_rvalid(m_axi_host0_rvalid),
    .m_axi_host0_rready(m_axi_host0_rready),
    .m_axi_host1_awaddr(m_axi_host1_awaddr),
    .m_axi_host1_awid(m_axi_host1_awid),
    .m_axi_host1_awlen(m_axi_host1_awlen),
    .m_axi_host1_awsize(m_axi_host1_awsize),
    .m_axi_host1_awburst(m_axi_host1_awburst),
    .m_axi_host1_awvalid(m_axi_host1_awvalid),
    .m_axi_host1_awready(m_axi_host1_awready),
    .m_axi_host1_wdata(m_axi_host1_wdata),
    .m_axi_host1_wstrb(m_axi_host1_wstrb),
    .m_axi_host1_wlast(m_axi_host1_wlast),
    .m_axi_host1_wvalid(m_axi_host1_wvalid),
    .m_axi_host1_wready(m_axi_host1_wready),
    .m_axi_host1_bid(m_axi_host1_bid),
    .m_axi_host1_bresp(m_axi_host1_bresp),
    .m_axi_host1_bvalid(m_axi_host1_bvalid),
    .m_axi_host1_bready(m_axi_host1_bready),
    .m_axi_host1_araddr(m_axi_host1_araddr),
    .m_axi_host1_arid(m_axi_host1_arid),
    .m_axi_host1_arlen(m_axi_host1_arlen),
    .m_axi_host1_arsize(m_axi_host1_arsize),
    .m_axi_host1_arburst(m_axi_host1_arburst),
    .m_axi_host1_arvalid(m_axi_host1_arvalid),
    .m_axi_host1_arready(m_axi_host1_arready),
    .m_axi_host1_rid(m_axi_host1_rid),
    .m_axi_host1_rdata(m_axi_host1_rdata),
    .m_axi_host1_rresp(m_axi_host1_rresp),
    .m_axi_host1_rlast(m_axi_host1_rlast),
    .m_axi_host1_rvalid(m_axi_host1_rvalid),
    .m_axi_host1_rready(m_axi_host1_rready),
    .m_axi_core0_awaddr(m_axi_core0_awaddr),
    .m_axi_core0_awid(m_axi_core0_awid),
    .m_axi_core0_awlen(m_axi_core0_awlen),
    .m_axi_core0_awsize(m_axi_core0_awsize),
    .m_axi_core0_awburst(m_axi_core0_awburst),
    .m_axi_core0_awvalid(m_axi_core0_awvalid),
    .m_axi_core0_awready(m_axi_core0_awready),
    .m_axi_core0_wdata(m_axi_core0_wdata),
    .m_axi_core0_wstrb(m_axi_core0_wstrb),
    .m_axi_core0_wlast(m_axi_core0_wlast),
    .m_axi_core0_wvalid(m_axi_core0_wvalid),
    .m_axi_core0_wready(m_axi_core0_wready),
    .m_axi_core0_bid(m_axi_core0_bid),
    .m_axi_core0_bresp(m_axi_core0_bresp),
    .m_axi_core0_bvalid(m_axi_core0_bvalid),
    .m_axi_core0_bready(m_axi_core0_bready),
    .m_axi_core0_araddr(m_axi_core0_araddr),
    .m_axi_core0_arid(m_axi_core0_arid),
    .m_axi_core0_arlen(m_axi_core0_arlen),
    .m_axi_core0_arsize(m_axi_core0_arsize),
    .m_axi_core0_arburst(m_axi_core0_arburst),
    .m_axi_core0_arvalid(m_axi_core0_arvalid),
    .m_axi_core0_arready(m_axi_core0_arready),
    .m_axi_core0_rid(m_axi_core0_rid),
    .m_axi_core0_rdata(m_axi_core0_rdata),
    .m_axi_core0_rresp(m_axi_core0_rresp),
    .m_axi_core0_rlast(m_axi_core0_rlast),
    .m_axi_core0_rvalid(m_axi_core0_rvalid),
    .m_axi_core0_rready(m_axi_core0_rready),
    .m_axi_core1_awaddr(m_axi_core1_awaddr),
    .m_axi_core1_awid(m_axi_core1_awid),
    .m_axi_core1_awlen(m_axi_core1_awlen),
    .m_axi_core1_awsize(m_axi_core1_awsize),
    .m_axi_core1_awburst(m_axi_core1_awburst),
    .m_axi_core1_awvalid(m_axi_core1_awvalid),
    .m_axi_core1_awready(m_axi_core1_awready),
    .m_axi_core1_wdata(m_axi_core1_wdata),
    .m_axi_core1_wstrb(m_axi_core1_wstrb),
    .m_axi_core1_wlast(m_axi_core1_wlast),
    .m_axi_core1_wvalid(m_axi_core1_wvalid),
    .m_axi_core1_wready(m_axi_core1_wready),
    .m_axi_core1_bid(m_axi_core1_bid),
    .m_axi_core1_bresp(m_axi_core1_bresp),
    .m_axi_core1_bvalid(m_axi_core1_bvalid),
    .m_axi_core1_bready(m_axi_core1_bready),
    .m_axi_core1_araddr(m_axi_core1_araddr),
    .m_axi_core1_arid(m_axi_core1_arid),
    .m_axi_core1_arlen(m_axi_core1_arlen),
    .m_axi_core1_arsize(m_axi_core1_arsize),
    .m_axi_core1_arburst(m_axi_core1_arburst),
    .m_axi_core1_arvalid(m_axi_core1_arvalid),
    .m_axi_core1_arready(m_axi_core1_arready),
    .m_axi_core1_rid(m_axi_core1_rid),
    .m_axi_core1_rdata(m_axi_core1_rdata),
    .m_axi_core1_rresp(m_axi_core1_rresp),
    .m_axi_core1_rlast(m_axi_core1_rlast),
    .m_axi_core1_rvalid(m_axi_core1_rvalid),
    .m_axi_core1_rready(m_axi_core1_rready)
  );
endmodule

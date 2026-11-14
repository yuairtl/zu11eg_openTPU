// openTPU ZU11EG first-board fabric. The block design owns PS, two DDR4 MIGs,
// DMA engines, clocking and board I/O; this module owns the unchanged openTPU
// core and the two native-to-AXI adapters.
module otpu_zu11eg_fabric (
  // Core clock and the 2x TMEM pump clock.
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 core_clk CLK" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME core_clk,ASSOCIATED_BUSIF S_AXI_CTRL:S_AXI_HOST:M_AXI_HOST0:M_AXI_HOST1,ASSOCIATED_RESET core_rstn,FREQ_HZ 100000000" *)
  input  logic core_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 core_clk_f CLK" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME core_clk_f,FREQ_HZ 200000000" *)
  input  logic core_clk_f,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 core_rstn RST" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME core_rstn,POLARITY ACTIVE_LOW" *)
  input  logic core_rstn,

  // Independent MIG AXI clocks/resets.
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 mig0_clk CLK" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME mig0_clk,ASSOCIATED_BUSIF M_AXI_CORE0,ASSOCIATED_RESET mig0_rst,FREQ_HZ 300000000" *)
  input  logic mig0_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 mig0_rst RST" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME mig0_rst,POLARITY ACTIVE_HIGH" *)
  input  logic mig0_rst,
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 mig1_clk CLK" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME mig1_clk,ASSOCIATED_BUSIF M_AXI_CORE1,ASSOCIATED_RESET mig1_rst,FREQ_HZ 300000000" *)
  input  logic mig1_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 mig1_rst RST" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME mig1_rst,POLARITY ACTIVE_HIGH" *)
  input  logic mig1_rst,

  input  logic [1:0] calib,
  output logic dci_locked,

  // AXI-Lite control from PS HPM0.
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL AWADDR" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI_CTRL,PROTOCOL AXI4LITE,DATA_WIDTH 32,ADDR_WIDTH 12,READ_WRITE_MODE READ_WRITE,HAS_BURST 0,HAS_LOCK 0,HAS_CACHE 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 1" *)
  input  logic [11:0] s_axi_ctrl_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL AWVALID" *)
  input  logic s_axi_ctrl_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL AWREADY" *)
  output logic s_axi_ctrl_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL WDATA" *)
  input  logic [31:0] s_axi_ctrl_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL WSTRB" *)
  input  logic [3:0] s_axi_ctrl_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL WVALID" *)
  input  logic s_axi_ctrl_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL WREADY" *)
  output logic s_axi_ctrl_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL BRESP" *)
  output logic [1:0] s_axi_ctrl_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL BVALID" *)
  output logic s_axi_ctrl_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL BREADY" *)
  input  logic s_axi_ctrl_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL ARADDR" *)
  input  logic [11:0] s_axi_ctrl_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL ARVALID" *)
  input  logic s_axi_ctrl_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL ARREADY" *)
  output logic s_axi_ctrl_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL RDATA" *)
  output logic [31:0] s_axi_ctrl_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL RRESP" *)
  output logic [1:0] s_axi_ctrl_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL RVALID" *)
  output logic s_axi_ctrl_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL RREADY" *)
  input  logic s_axi_ctrl_rready,

  // AXI4 host data from the merged H2C/C2H DMA path. The CDMA adds the
  // 0x8_0000_0000 PL aperture; only the low 32 bits select the openTPU window.
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWADDR" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI_HOST,PROTOCOL AXI4,DATA_WIDTH 128,ADDR_WIDTH 64,ID_WIDTH 1,READ_WRITE_MODE READ_WRITE,HAS_BURST 1,HAS_LOCK 0,HAS_CACHE 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 1,SUPPORTS_NARROW_BURST 0" *)
  input  logic [63:0] s_axi_host_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWID" *)
  input  logic [0:0] s_axi_host_awid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWLEN" *)
  input  logic [7:0] s_axi_host_awlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWSIZE" *)
  input  logic [2:0] s_axi_host_awsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWBURST" *)
  input  logic [1:0] s_axi_host_awburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWVALID" *)
  input  logic s_axi_host_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST AWREADY" *)
  output logic s_axi_host_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST WDATA" *)
  input  logic [127:0] s_axi_host_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST WSTRB" *)
  input  logic [15:0] s_axi_host_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST WLAST" *)
  input  logic s_axi_host_wlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST WVALID" *)
  input  logic s_axi_host_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST WREADY" *)
  output logic s_axi_host_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST BID" *)
  output logic [0:0] s_axi_host_bid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST BRESP" *)
  output logic [1:0] s_axi_host_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST BVALID" *)
  output logic s_axi_host_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST BREADY" *)
  input  logic s_axi_host_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARADDR" *)
  input  logic [63:0] s_axi_host_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARID" *)
  input  logic [0:0] s_axi_host_arid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARLEN" *)
  input  logic [7:0] s_axi_host_arlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARSIZE" *)
  input  logic [2:0] s_axi_host_arsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARBURST" *)
  input  logic [1:0] s_axi_host_arburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARVALID" *)
  input  logic s_axi_host_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST ARREADY" *)
  output logic s_axi_host_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST RID" *)
  output logic [0:0] s_axi_host_rid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST RDATA" *)
  output logic [127:0] s_axi_host_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST RRESP" *)
  output logic [1:0] s_axi_host_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST RLAST" *)
  output logic s_axi_host_rlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST RVALID" *)
  output logic s_axi_host_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HOST RREADY" *)
  input  logic s_axi_host_rready,

  // Per-channel AXI masters into the MIG fabric.
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWADDR" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI_HOST0,PROTOCOL AXI4,DATA_WIDTH 128,ADDR_WIDTH 32,ID_WIDTH 1,READ_WRITE_MODE READ_WRITE,HAS_BURST 1,HAS_LOCK 0,HAS_CACHE 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 1,SUPPORTS_NARROW_BURST 0" *)
  output logic [31:0] m_axi_host0_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWID" *)
  output logic [0:0] m_axi_host0_awid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWLEN" *)
  output logic [7:0] m_axi_host0_awlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWSIZE" *)
  output logic [2:0] m_axi_host0_awsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWBURST" *)
  output logic [1:0] m_axi_host0_awburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWVALID" *)
  output logic m_axi_host0_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 AWREADY" *)
  input logic m_axi_host0_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 WDATA" *)
  output logic [127:0] m_axi_host0_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 WSTRB" *)
  output logic [15:0] m_axi_host0_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 WLAST" *)
  output logic m_axi_host0_wlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 WVALID" *)
  output logic m_axi_host0_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 WREADY" *)
  input logic m_axi_host0_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 BID" *)
  input logic [0:0] m_axi_host0_bid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 BRESP" *)
  input logic [1:0] m_axi_host0_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 BVALID" *)
  input logic m_axi_host0_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 BREADY" *)
  output logic m_axi_host0_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARADDR" *)
  output logic [31:0] m_axi_host0_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARID" *)
  output logic [0:0] m_axi_host0_arid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARLEN" *)
  output logic [7:0] m_axi_host0_arlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARSIZE" *)
  output logic [2:0] m_axi_host0_arsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARBURST" *)
  output logic [1:0] m_axi_host0_arburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARVALID" *)
  output logic m_axi_host0_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 ARREADY" *)
  input logic m_axi_host0_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 RID" *)
  input logic [0:0] m_axi_host0_rid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 RDATA" *)
  input logic [127:0] m_axi_host0_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 RRESP" *)
  input logic [1:0] m_axi_host0_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 RLAST" *)
  input logic m_axi_host0_rlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 RVALID" *)
  input logic m_axi_host0_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST0 RREADY" *)
  output logic m_axi_host0_rready,

  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWADDR" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI_HOST1,PROTOCOL AXI4,DATA_WIDTH 128,ADDR_WIDTH 32,ID_WIDTH 1,READ_WRITE_MODE READ_WRITE,HAS_BURST 1,HAS_LOCK 0,HAS_CACHE 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 1,SUPPORTS_NARROW_BURST 0" *)
  output logic [31:0] m_axi_host1_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWID" *)
  output logic [0:0] m_axi_host1_awid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWLEN" *)
  output logic [7:0] m_axi_host1_awlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWSIZE" *)
  output logic [2:0] m_axi_host1_awsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWBURST" *)
  output logic [1:0] m_axi_host1_awburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWVALID" *)
  output logic m_axi_host1_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 AWREADY" *)
  input logic m_axi_host1_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 WDATA" *)
  output logic [127:0] m_axi_host1_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 WSTRB" *)
  output logic [15:0] m_axi_host1_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 WLAST" *)
  output logic m_axi_host1_wlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 WVALID" *)
  output logic m_axi_host1_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 WREADY" *)
  input logic m_axi_host1_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 BID" *)
  input logic [0:0] m_axi_host1_bid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 BRESP" *)
  input logic [1:0] m_axi_host1_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 BVALID" *)
  input logic m_axi_host1_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 BREADY" *)
  output logic m_axi_host1_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARADDR" *)
  output logic [31:0] m_axi_host1_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARID" *)
  output logic [0:0] m_axi_host1_arid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARLEN" *)
  output logic [7:0] m_axi_host1_arlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARSIZE" *)
  output logic [2:0] m_axi_host1_arsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARBURST" *)
  output logic [1:0] m_axi_host1_arburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARVALID" *)
  output logic m_axi_host1_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 ARREADY" *)
  input logic m_axi_host1_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 RID" *)
  input logic [0:0] m_axi_host1_rid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 RDATA" *)
  input logic [127:0] m_axi_host1_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 RRESP" *)
  input logic [1:0] m_axi_host1_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 RLAST" *)
  input logic m_axi_host1_rlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 RVALID" *)
  input logic m_axi_host1_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_HOST1 RREADY" *)
  output logic m_axi_host1_rready,

  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWADDR" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI_CORE0,PROTOCOL AXI4,DATA_WIDTH 512,ADDR_WIDTH 32,ID_WIDTH 1,READ_WRITE_MODE READ_WRITE,HAS_BURST 1,HAS_LOCK 0,HAS_CACHE 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 1,SUPPORTS_NARROW_BURST 0" *)
  output logic [31:0] m_axi_core0_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWID" *)
  output logic m_axi_core0_awid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWLEN" *)
  output logic [7:0] m_axi_core0_awlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWSIZE" *)
  output logic [2:0] m_axi_core0_awsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWBURST" *)
  output logic [1:0] m_axi_core0_awburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWVALID" *)
  output logic m_axi_core0_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 AWREADY" *)
  input logic m_axi_core0_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 WDATA" *)
  output logic [511:0] m_axi_core0_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 WSTRB" *)
  output logic [63:0] m_axi_core0_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 WLAST" *)
  output logic m_axi_core0_wlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 WVALID" *)
  output logic m_axi_core0_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 WREADY" *)
  input logic m_axi_core0_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 BID" *)
  input logic m_axi_core0_bid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 BRESP" *)
  input logic [1:0] m_axi_core0_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 BVALID" *)
  input logic m_axi_core0_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 BREADY" *)
  output logic m_axi_core0_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARADDR" *)
  output logic [31:0] m_axi_core0_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARID" *)
  output logic m_axi_core0_arid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARLEN" *)
  output logic [7:0] m_axi_core0_arlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARSIZE" *)
  output logic [2:0] m_axi_core0_arsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARBURST" *)
  output logic [1:0] m_axi_core0_arburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARVALID" *)
  output logic m_axi_core0_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 ARREADY" *)
  input logic m_axi_core0_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 RID" *)
  input logic m_axi_core0_rid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 RDATA" *)
  input logic [511:0] m_axi_core0_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 RRESP" *)
  input logic [1:0] m_axi_core0_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 RLAST" *)
  input logic m_axi_core0_rlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 RVALID" *)
  input logic m_axi_core0_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE0 RREADY" *)
  output logic m_axi_core0_rready,

  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWADDR" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI_CORE1,PROTOCOL AXI4,DATA_WIDTH 512,ADDR_WIDTH 32,ID_WIDTH 1,READ_WRITE_MODE READ_WRITE,HAS_BURST 1,HAS_LOCK 0,HAS_CACHE 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 1,SUPPORTS_NARROW_BURST 0" *)
  output logic [31:0] m_axi_core1_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWID" *)
  output logic m_axi_core1_awid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWLEN" *)
  output logic [7:0] m_axi_core1_awlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWSIZE" *)
  output logic [2:0] m_axi_core1_awsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWBURST" *)
  output logic [1:0] m_axi_core1_awburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWVALID" *)
  output logic m_axi_core1_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 AWREADY" *)
  input logic m_axi_core1_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 WDATA" *)
  output logic [511:0] m_axi_core1_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 WSTRB" *)
  output logic [63:0] m_axi_core1_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 WLAST" *)
  output logic m_axi_core1_wlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 WVALID" *)
  output logic m_axi_core1_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 WREADY" *)
  input logic m_axi_core1_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 BID" *)
  input logic m_axi_core1_bid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 BRESP" *)
  input logic [1:0] m_axi_core1_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 BVALID" *)
  input logic m_axi_core1_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 BREADY" *)
  output logic m_axi_core1_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARADDR" *)
  output logic [31:0] m_axi_core1_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARID" *)
  output logic m_axi_core1_arid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARLEN" *)
  output logic [7:0] m_axi_core1_arlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARSIZE" *)
  output logic [2:0] m_axi_core1_arsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARBURST" *)
  output logic [1:0] m_axi_core1_arburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARVALID" *)
  output logic m_axi_core1_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 ARREADY" *)
  input logic m_axi_core1_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 RID" *)
  input logic m_axi_core1_rid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 RDATA" *)
  input logic [511:0] m_axi_core1_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 RRESP" *)
  input logic [1:0] m_axi_core1_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 RLAST" *)
  input logic m_axi_core1_rlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 RVALID" *)
  input logic m_axi_core1_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_CORE1 RREADY" *)
  output logic m_axi_core1_rready
);
  localparam int S = 1;
  localparam int MCOLS = 4;
  localparam int ACT_ROWS = 16;
  localparam int LANES = 8;
  localparam logic [31:0] ARCH_HASH = 32'h4ffd1e17;
  logic core_rst_i;
  assign core_rst_i = ~core_rstn;

  // The DDR4 pins use DCI standards in the ZU11EG multifunction banks. Pulse
  // DCIRESET after configuration and hold both MIG resets through their
  // proc_sys_reset dcm_locked inputs until the DCI controller is locked.
  otpu_dci_reset u_dci_reset (
    .reset(core_rst_i),
    .locked(dci_locked)
  );

  logic [1:0] calib_core;
  otpu_calib_sync u_calib0 (
    .src_clk(mig0_clk), .src_in(calib[0]),
    .dest_clk(core_clk), .dest_out(calib_core[0])
  );
  otpu_calib_sync u_calib1 (
    .src_clk(mig1_clk), .src_in(calib[1]),
    .dest_clk(core_clk), .dest_out(calib_core[1])
  );

  logic [11:0] ctl_awaddr, ctl_araddr;
  logic [31:0] ctl_wdata, ctl_rdata;
  logic [3:0] ctl_wstrb;
  logic ctl_awvalid, ctl_awready, ctl_wvalid, ctl_wready;
  logic [1:0] ctl_bresp, ctl_rresp;
  logic ctl_bvalid, ctl_bready, ctl_arvalid, ctl_arready;
  logic ctl_rvalid, ctl_rready;

  // AXI4-Lite does not require AW and W in the same cycle. Join them before
  // the upstream control slave, which was written for that narrower contract.
  otpu_axil_join #(.AW(12)) u_axil_join (
    .clk(core_clk), .rst(core_rst_i),
    .s_awaddr(s_axi_ctrl_awaddr), .s_awvalid(s_axi_ctrl_awvalid),
    .s_awready(s_axi_ctrl_awready),
    .s_wdata(s_axi_ctrl_wdata), .s_wstrb(s_axi_ctrl_wstrb),
    .s_wvalid(s_axi_ctrl_wvalid), .s_wready(s_axi_ctrl_wready),
    .s_bresp(s_axi_ctrl_bresp), .s_bvalid(s_axi_ctrl_bvalid),
    .s_bready(s_axi_ctrl_bready),
    .s_araddr(s_axi_ctrl_araddr), .s_arvalid(s_axi_ctrl_arvalid),
    .s_arready(s_axi_ctrl_arready), .s_rdata(s_axi_ctrl_rdata),
    .s_rresp(s_axi_ctrl_rresp), .s_rvalid(s_axi_ctrl_rvalid),
    .s_rready(s_axi_ctrl_rready),
    .m_awaddr(ctl_awaddr), .m_awvalid(ctl_awvalid), .m_awready(ctl_awready),
    .m_wdata(ctl_wdata), .m_wstrb(ctl_wstrb), .m_wvalid(ctl_wvalid),
    .m_wready(ctl_wready), .m_bresp(ctl_bresp), .m_bvalid(ctl_bvalid),
    .m_bready(ctl_bready),
    .m_araddr(ctl_araddr), .m_arvalid(ctl_arvalid), .m_arready(ctl_arready),
    .m_rdata(ctl_rdata), .m_rresp(ctl_rresp), .m_rvalid(ctl_rvalid),
    .m_rready(ctl_rready)
  );

  logic [2*S-1:0] n_cvalid, n_cready, n_cwe, n_wvalid, n_wready, n_rvalid;
  logic [2*S-1:0][24:0] n_caddr;
  logic [2*S-1:0][511:0] n_wdata, n_rdata;
  logic [2*S-1:0][63:0] n_wmask;
  logic [2*S-1:0][15:0] n_wdone;
  logic [2*S-1:0] n_err;
  logic [3:0] i2c_lo_unused;
  logic [2:0] led;

  otpu_board #(
    .S(S), .D(128), .MCOLS(MCOLS), .ACT_BLOCKS(128), .ACT_ROWS(ACT_ROWS),
    .TMEM_WORDS(65536), .IMEM_WORDS(32768), .FIFO_DEPTH(1024), .LANES(LANES),
    .WIN(16), .TMEM_IMPL(3), .TMEM_NSB(2), .TMEM_RPL(1'b1),
    .TMEM_TDP(1'b1), .TMEM_GST(1'b1), .TMEM_PMP(1),
    // The target file's RPB=0 means one reader per lane; otpu_board sees 8*LANES.
    .RPB(8*LANES), .WPB(1), .MXU_IMPL(2), .MXU_CL(16), .MXU_E(4),
    .VPU_CL(2), .ULANES(8), .CORE_KHZ(100000), .BUILD_ID(32'h0),
    .DDR_MTS(2400), .TRACE_DEPTH(16384), .PQ_WIN(1024),
    .HAS_TEMP(1'b0), .HAS_I2C(1'b0), .CHASH(1'b1), .DSTEP(1'b1), .HOSTCAL(1'b0),
    .COLL_GATHER(1'b1), .SEQ_WC(1'b1), .PLATFORM(3), .ARCH_HASH(ARCH_HASH),
    .TMEM_PMP_STYLE("block")
  ) u_board (
    .clk(core_clk), .clk_f(core_clk_f), .rst(core_rst_i), .ctl_mrst(core_rst_i),
    .calib(calib_core), .ded(2'b0), .temp(12'b0), .led(led),
    .i2c_lo(i2c_lo_unused), .i2c_pin(5'b11111),
    .s_ctl_awaddr(ctl_awaddr), .s_ctl_awvalid(ctl_awvalid),
    .s_ctl_awready(ctl_awready), .s_ctl_wdata(ctl_wdata),
    .s_ctl_wstrb(ctl_wstrb), .s_ctl_wvalid(ctl_wvalid),
    .s_ctl_wready(ctl_wready), .s_ctl_bresp(ctl_bresp),
    .s_ctl_bvalid(ctl_bvalid), .s_ctl_bready(ctl_bready),
    .s_ctl_araddr(ctl_araddr), .s_ctl_arvalid(ctl_arvalid),
    .s_ctl_arready(ctl_arready), .s_ctl_rdata(ctl_rdata),
    .s_ctl_rresp(ctl_rresp), .s_ctl_rvalid(ctl_rvalid),
    .s_ctl_rready(ctl_rready),
    .n_cvalid(n_cvalid), .n_cready(n_cready), .n_cwe(n_cwe),
    .n_caddr(n_caddr), .n_wvalid(n_wvalid), .n_wready(n_wready),
    .n_wdata(n_wdata), .n_wmask(n_wmask), .n_rvalid(n_rvalid),
    .n_rdata(n_rdata), .n_wdone(n_wdone), .n_err(n_err)
  );

  logic [1:0] mig_aclk, mig_arst;
  logic [1:0][31:0] core_awaddr, core_araddr;
  logic [1:0][7:0] core_awlen, core_arlen;
  logic [1:0][2:0] core_awsize, core_arsize;
  logic [1:0][1:0] core_awburst, core_arburst;
  logic [1:0] core_awlock, core_arlock;
  logic [1:0][3:0] core_awcache, core_arcache;
  logic [1:0][2:0] core_awprot, core_arprot;
  logic [1:0][3:0] core_awqos, core_arqos;
  logic [1:0] core_awvalid, core_awready, core_wvalid, core_wready, core_wlast;
  logic [1:0] core_arvalid, core_arready;
  logic [1:0][511:0] core_wdata, core_rdata;
  logic [1:0][63:0] core_wstrb;
  logic [1:0][0:0] core_bid, core_rid;
  logic [1:0][1:0] core_bresp, core_rresp;
  logic [1:0] core_bvalid, core_bready, core_rvalid, core_rready, core_rlast;

  assign mig_aclk = {mig1_clk, mig0_clk};
  assign mig_arst = {mig1_rst, mig0_rst};

  otpu_native_axi_sys #(
    .MAX_BURST(64), .CMD_DEPTH(64), .WD_DEPTH(64), .RD_DEPTH(128),
    .EVT_DEPTH(16), .COALESCE_WAIT(32), .TIMEOUT_CYCLES(1000000), .IDW(1)
  ) u_native_axi (
    .clk(core_clk), .rst(core_rst_i),
    .n_cvalid(n_cvalid), .n_cready(n_cready), .n_cwe(n_cwe), .n_caddr(n_caddr),
    .n_wvalid(n_wvalid), .n_wready(n_wready), .n_wdata(n_wdata), .n_wmask(n_wmask),
    .n_rvalid(n_rvalid), .n_rdata(n_rdata), .n_wdone(n_wdone), .n_err(n_err),
    .aclk(mig_aclk), .arst(mig_arst),
    .m_awid({m_axi_core1_awid, m_axi_core0_awid}),
    .m_awaddr(core_awaddr), .m_awlen(core_awlen), .m_awsize(core_awsize),
    .m_awburst(core_awburst), .m_awlock(core_awlock), .m_awcache(core_awcache),
    .m_awprot(core_awprot), .m_awqos(core_awqos), .m_awvalid(core_awvalid),
    .m_awready(core_awready), .m_wdata(core_wdata), .m_wstrb(core_wstrb),
    .m_wlast(core_wlast), .m_wvalid(core_wvalid), .m_wready(core_wready),
    .m_bid(core_bid), .m_bresp(core_bresp), .m_bvalid(core_bvalid),
    .m_bready(core_bready), .m_arid({m_axi_core1_arid, m_axi_core0_arid}),
    .m_araddr(core_araddr), .m_arlen(core_arlen), .m_arsize(core_arsize),
    .m_arburst(core_arburst), .m_arlock(core_arlock), .m_arcache(core_arcache),
    .m_arprot(core_arprot), .m_arqos(core_arqos), .m_arvalid(core_arvalid),
    .m_arready(core_arready), .m_rid(core_rid), .m_rdata(core_rdata),
    .m_rresp(core_rresp), .m_rlast(core_rlast), .m_rvalid(core_rvalid),
    .m_rready(core_rready)
  );

  assign m_axi_core0_awaddr = core_awaddr[0];
  assign m_axi_core0_awlen = core_awlen[0];
  assign m_axi_core0_awsize = core_awsize[0];
  assign m_axi_core0_awburst = core_awburst[0];
  assign m_axi_core0_awvalid = core_awvalid[0];
  assign m_axi_core0_wdata = core_wdata[0];
  assign m_axi_core0_wstrb = core_wstrb[0];
  assign m_axi_core0_wlast = core_wlast[0];
  assign m_axi_core0_wvalid = core_wvalid[0];
  assign m_axi_core0_bready = core_bready[0];
  assign m_axi_core0_araddr = core_araddr[0];
  assign m_axi_core0_arlen = core_arlen[0];
  assign m_axi_core0_arsize = core_arsize[0];
  assign m_axi_core0_arburst = core_arburst[0];
  assign m_axi_core0_arvalid = core_arvalid[0];
  assign m_axi_core0_rready = core_rready[0];
  assign core_awready[0] = m_axi_core0_awready;
  assign core_wready[0] = m_axi_core0_wready;
  assign core_bid[0] = m_axi_core0_bid;
  assign core_bresp[0] = m_axi_core0_bresp;
  assign core_bvalid[0] = m_axi_core0_bvalid;
  assign core_arready[0] = m_axi_core0_arready;
  assign core_rid[0] = m_axi_core0_rid;
  assign core_rdata[0] = m_axi_core0_rdata;
  assign core_rresp[0] = m_axi_core0_rresp;
  assign core_rlast[0] = m_axi_core0_rlast;
  assign core_rvalid[0] = m_axi_core0_rvalid;

  assign m_axi_core1_awaddr = core_awaddr[1];
  assign m_axi_core1_awlen = core_awlen[1];
  assign m_axi_core1_awsize = core_awsize[1];
  assign m_axi_core1_awburst = core_awburst[1];
  assign m_axi_core1_awvalid = core_awvalid[1];
  assign m_axi_core1_wdata = core_wdata[1];
  assign m_axi_core1_wstrb = core_wstrb[1];
  assign m_axi_core1_wlast = core_wlast[1];
  assign m_axi_core1_wvalid = core_wvalid[1];
  assign m_axi_core1_bready = core_bready[1];
  assign m_axi_core1_araddr = core_araddr[1];
  assign m_axi_core1_arlen = core_arlen[1];
  assign m_axi_core1_arsize = core_arsize[1];
  assign m_axi_core1_arburst = core_arburst[1];
  assign m_axi_core1_arvalid = core_arvalid[1];
  assign m_axi_core1_rready = core_rready[1];
  assign core_awready[1] = m_axi_core1_awready;
  assign core_wready[1] = m_axi_core1_wready;
  assign core_bid[1] = m_axi_core1_bid;
  assign core_bresp[1] = m_axi_core1_bresp;
  assign core_bvalid[1] = m_axi_core1_bvalid;
  assign core_arready[1] = m_axi_core1_arready;
  assign core_rid[1] = m_axi_core1_rid;
  assign core_rdata[1] = m_axi_core1_rdata;
  assign core_rresp[1] = m_axi_core1_rresp;
  assign core_rlast[1] = m_axi_core1_rlast;
  assign core_rvalid[1] = m_axi_core1_rvalid;

  logic [31:0] host_awaddr32, host_araddr32;
  assign host_awaddr32 = s_axi_host_awaddr[31:0];
  assign host_araddr32 = s_axi_host_araddr[31:0];

  otpu_dma_split #(.REG(1'b0), .IDW(1), .DW(128)) u_host_split (
    .clk(core_clk), .rst(core_rst_i),
    .s_awvalid(s_axi_host_awvalid), .s_awready(s_axi_host_awready),
    .s_awid(s_axi_host_awid), .s_awaddr(host_awaddr32), .s_awlen(s_axi_host_awlen),
    .s_wvalid(s_axi_host_wvalid), .s_wready(s_axi_host_wready),
    .s_wdata(s_axi_host_wdata), .s_wstrb(s_axi_host_wstrb),
    .s_wlast(s_axi_host_wlast), .s_bvalid(s_axi_host_bvalid),
    .s_bready(s_axi_host_bready), .s_bid(s_axi_host_bid), .s_bresp(s_axi_host_bresp),
    .s_arvalid(s_axi_host_arvalid), .s_arready(s_axi_host_arready),
    .s_arid(s_axi_host_arid), .s_araddr(host_araddr32), .s_arlen(s_axi_host_arlen),
    .s_rvalid(s_axi_host_rvalid), .s_rready(s_axi_host_rready),
    .s_rid(s_axi_host_rid), .s_rdata(s_axi_host_rdata),
    .s_rresp(s_axi_host_rresp), .s_rlast(s_axi_host_rlast),
    .m_awvalid({m_axi_host1_awvalid, m_axi_host0_awvalid}),
    .m_awready({m_axi_host1_awready, m_axi_host0_awready}),
    .m_awid({m_axi_host1_awid, m_axi_host0_awid}),
    .m_awaddr({m_axi_host1_awaddr, m_axi_host0_awaddr}),
    .m_awlen({m_axi_host1_awlen, m_axi_host0_awlen}),
    .m_wvalid({m_axi_host1_wvalid, m_axi_host0_wvalid}),
    .m_wready({m_axi_host1_wready, m_axi_host0_wready}),
    .m_wdata({m_axi_host1_wdata, m_axi_host0_wdata}),
    .m_wstrb({m_axi_host1_wstrb, m_axi_host0_wstrb}),
    .m_wlast({m_axi_host1_wlast, m_axi_host0_wlast}),
    .m_bvalid({m_axi_host1_bvalid, m_axi_host0_bvalid}),
    .m_bready({m_axi_host1_bready, m_axi_host0_bready}),
    .m_bid({m_axi_host1_bid, m_axi_host0_bid}),
    .m_bresp({m_axi_host1_bresp, m_axi_host0_bresp}),
    .m_arvalid({m_axi_host1_arvalid, m_axi_host0_arvalid}),
    .m_arready({m_axi_host1_arready, m_axi_host0_arready}),
    .m_arid({m_axi_host1_arid, m_axi_host0_arid}),
    .m_araddr({m_axi_host1_araddr, m_axi_host0_araddr}),
    .m_arlen({m_axi_host1_arlen, m_axi_host0_arlen}),
    .m_rvalid({m_axi_host1_rvalid, m_axi_host0_rvalid}),
    .m_rready({m_axi_host1_rready, m_axi_host0_rready}),
    .m_rid({m_axi_host1_rid, m_axi_host0_rid}),
    .m_rdata({m_axi_host1_rdata, m_axi_host0_rdata}),
    .m_rresp({m_axi_host1_rresp, m_axi_host0_rresp}),
    .m_rlast({m_axi_host1_rlast, m_axi_host0_rlast})
  );

  assign m_axi_host0_awsize = 3'd4;
  assign m_axi_host0_awburst = 2'b01;
  assign m_axi_host0_arsize = 3'd4;
  assign m_axi_host0_arburst = 2'b01;
  assign m_axi_host1_awsize = 3'd4;
  assign m_axi_host1_awburst = 2'b01;
  assign m_axi_host1_arsize = 3'd4;
  assign m_axi_host1_arburst = 2'b01;

  // Keep optional AXI attributes generated by the adapters visible at the module
  // boundary. The downstream MIG interconnect ties unsupported attributes legally.
  logic unused_ok;
  assign unused_ok = ^{core_awlock, core_arlock, core_awcache, core_arcache,
                       core_awprot, core_arprot, core_awqos, core_arqos,
                       s_axi_ctrl_wstrb, s_axi_host_awsize,
                       s_axi_host_awburst, s_axi_host_arsize,
                       s_axi_host_arburst};
endmodule

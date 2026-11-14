`timescale 1ps / 1ps

module tb_system_wrapper_smoke;
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

  initial begin
    ddr_clk0_clk_p = 1'b0;
    ddr_clk1_clk_p = 1'b0;
    UART_0_rxd = 1'b1;
    #20_000_000;
    $display("PASS tb_system_wrapper_smoke elapsed=20us");
    $finish;
  end
endmodule

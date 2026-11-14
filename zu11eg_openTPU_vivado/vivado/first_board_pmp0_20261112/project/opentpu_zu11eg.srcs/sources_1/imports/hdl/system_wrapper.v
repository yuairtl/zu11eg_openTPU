//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (lin64) Build 6299465 Fri Nov 14 12:34:56 MST 2025
//Date        : Thu Nov 12 13:57:06 2026
//Host        : ubuntu-peta running 64-bit Ubuntu 22.04.5 LTS
//Command     : generate_target system_wrapper.bd
//Design      : system_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module system_wrapper
   (UART_0_rxd,
    UART_0_txd,
    ddr4_rtl_0_act_n,
    ddr4_rtl_0_adr,
    ddr4_rtl_0_ba,
    ddr4_rtl_0_bg,
    ddr4_rtl_0_ck_c,
    ddr4_rtl_0_ck_t,
    ddr4_rtl_0_cke,
    ddr4_rtl_0_cs_n,
    ddr4_rtl_0_dm_n,
    ddr4_rtl_0_dq,
    ddr4_rtl_0_dqs_c,
    ddr4_rtl_0_dqs_t,
    ddr4_rtl_0_odt,
    ddr4_rtl_0_reset_n,
    ddr4_rtl_1_act_n,
    ddr4_rtl_1_adr,
    ddr4_rtl_1_ba,
    ddr4_rtl_1_bg,
    ddr4_rtl_1_ck_c,
    ddr4_rtl_1_ck_t,
    ddr4_rtl_1_cke,
    ddr4_rtl_1_cs_n,
    ddr4_rtl_1_dm_n,
    ddr4_rtl_1_dq,
    ddr4_rtl_1_dqs_c,
    ddr4_rtl_1_dqs_t,
    ddr4_rtl_1_odt,
    ddr4_rtl_1_reset_n,
    ddr_clk0_clk_n,
    ddr_clk0_clk_p,
    ddr_clk1_clk_n,
    ddr_clk1_clk_p);
  input UART_0_rxd;
  output UART_0_txd;
  output ddr4_rtl_0_act_n;
  output [16:0]ddr4_rtl_0_adr;
  output [1:0]ddr4_rtl_0_ba;
  output [0:0]ddr4_rtl_0_bg;
  output [0:0]ddr4_rtl_0_ck_c;
  output [0:0]ddr4_rtl_0_ck_t;
  output [0:0]ddr4_rtl_0_cke;
  output [0:0]ddr4_rtl_0_cs_n;
  inout [7:0]ddr4_rtl_0_dm_n;
  inout [63:0]ddr4_rtl_0_dq;
  inout [7:0]ddr4_rtl_0_dqs_c;
  inout [7:0]ddr4_rtl_0_dqs_t;
  output [0:0]ddr4_rtl_0_odt;
  output ddr4_rtl_0_reset_n;
  output ddr4_rtl_1_act_n;
  output [16:0]ddr4_rtl_1_adr;
  output [1:0]ddr4_rtl_1_ba;
  output [0:0]ddr4_rtl_1_bg;
  output [0:0]ddr4_rtl_1_ck_c;
  output [0:0]ddr4_rtl_1_ck_t;
  output [0:0]ddr4_rtl_1_cke;
  output [0:0]ddr4_rtl_1_cs_n;
  inout [7:0]ddr4_rtl_1_dm_n;
  inout [63:0]ddr4_rtl_1_dq;
  inout [7:0]ddr4_rtl_1_dqs_c;
  inout [7:0]ddr4_rtl_1_dqs_t;
  output [0:0]ddr4_rtl_1_odt;
  output ddr4_rtl_1_reset_n;
  input ddr_clk0_clk_n;
  input ddr_clk0_clk_p;
  input ddr_clk1_clk_n;
  input ddr_clk1_clk_p;

  wire UART_0_rxd;
  wire UART_0_txd;
  wire ddr4_rtl_0_act_n;
  wire [16:0]ddr4_rtl_0_adr;
  wire [1:0]ddr4_rtl_0_ba;
  wire [0:0]ddr4_rtl_0_bg;
  wire [0:0]ddr4_rtl_0_ck_c;
  wire [0:0]ddr4_rtl_0_ck_t;
  wire [0:0]ddr4_rtl_0_cke;
  wire [0:0]ddr4_rtl_0_cs_n;
  wire [7:0]ddr4_rtl_0_dm_n;
  wire [63:0]ddr4_rtl_0_dq;
  wire [7:0]ddr4_rtl_0_dqs_c;
  wire [7:0]ddr4_rtl_0_dqs_t;
  wire [0:0]ddr4_rtl_0_odt;
  wire ddr4_rtl_0_reset_n;
  wire ddr4_rtl_1_act_n;
  wire [16:0]ddr4_rtl_1_adr;
  wire [1:0]ddr4_rtl_1_ba;
  wire [0:0]ddr4_rtl_1_bg;
  wire [0:0]ddr4_rtl_1_ck_c;
  wire [0:0]ddr4_rtl_1_ck_t;
  wire [0:0]ddr4_rtl_1_cke;
  wire [0:0]ddr4_rtl_1_cs_n;
  wire [7:0]ddr4_rtl_1_dm_n;
  wire [63:0]ddr4_rtl_1_dq;
  wire [7:0]ddr4_rtl_1_dqs_c;
  wire [7:0]ddr4_rtl_1_dqs_t;
  wire [0:0]ddr4_rtl_1_odt;
  wire ddr4_rtl_1_reset_n;
  wire ddr_clk0_clk_n;
  wire ddr_clk0_clk_p;
  wire ddr_clk1_clk_n;
  wire ddr_clk1_clk_p;

  system system_i
       (.UART_0_rxd(UART_0_rxd),
        .UART_0_txd(UART_0_txd),
        .ddr4_rtl_0_act_n(ddr4_rtl_0_act_n),
        .ddr4_rtl_0_adr(ddr4_rtl_0_adr),
        .ddr4_rtl_0_ba(ddr4_rtl_0_ba),
        .ddr4_rtl_0_bg(ddr4_rtl_0_bg),
        .ddr4_rtl_0_ck_c(ddr4_rtl_0_ck_c),
        .ddr4_rtl_0_ck_t(ddr4_rtl_0_ck_t),
        .ddr4_rtl_0_cke(ddr4_rtl_0_cke),
        .ddr4_rtl_0_cs_n(ddr4_rtl_0_cs_n),
        .ddr4_rtl_0_dm_n(ddr4_rtl_0_dm_n),
        .ddr4_rtl_0_dq(ddr4_rtl_0_dq),
        .ddr4_rtl_0_dqs_c(ddr4_rtl_0_dqs_c),
        .ddr4_rtl_0_dqs_t(ddr4_rtl_0_dqs_t),
        .ddr4_rtl_0_odt(ddr4_rtl_0_odt),
        .ddr4_rtl_0_reset_n(ddr4_rtl_0_reset_n),
        .ddr4_rtl_1_act_n(ddr4_rtl_1_act_n),
        .ddr4_rtl_1_adr(ddr4_rtl_1_adr),
        .ddr4_rtl_1_ba(ddr4_rtl_1_ba),
        .ddr4_rtl_1_bg(ddr4_rtl_1_bg),
        .ddr4_rtl_1_ck_c(ddr4_rtl_1_ck_c),
        .ddr4_rtl_1_ck_t(ddr4_rtl_1_ck_t),
        .ddr4_rtl_1_cke(ddr4_rtl_1_cke),
        .ddr4_rtl_1_cs_n(ddr4_rtl_1_cs_n),
        .ddr4_rtl_1_dm_n(ddr4_rtl_1_dm_n),
        .ddr4_rtl_1_dq(ddr4_rtl_1_dq),
        .ddr4_rtl_1_dqs_c(ddr4_rtl_1_dqs_c),
        .ddr4_rtl_1_dqs_t(ddr4_rtl_1_dqs_t),
        .ddr4_rtl_1_odt(ddr4_rtl_1_odt),
        .ddr4_rtl_1_reset_n(ddr4_rtl_1_reset_n),
        .ddr_clk0_clk_n(ddr_clk0_clk_n),
        .ddr_clk0_clk_p(ddr_clk0_clk_p),
        .ddr_clk1_clk_n(ddr_clk1_clk_n),
        .ddr_clk1_clk_p(ddr_clk1_clk_p));
endmodule

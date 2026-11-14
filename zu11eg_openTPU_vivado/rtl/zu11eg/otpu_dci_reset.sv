// Configuration-bank DCI reset. UltraScale/UltraScale+ requires DCIRESET when
// DCI I/O standards are used in multifunction banks 60, 65, or 70.
module otpu_dci_reset (
  input  logic reset,
  output logic locked
);
`ifdef SYNTHESIS
  DCIRESET u_dci (
    .LOCKED(locked),
    .RST(reset)
  );
`else
  assign locked = !reset;
`endif
endmodule

// Slow calibration level from one MIG clock domain into the Core clock.
module otpu_calib_sync (
  input  logic src_clk,
  input  logic src_in,
  input  logic dest_clk,
  output logic dest_out
);
`ifdef SYNTHESIS
  xpm_cdc_array_single #(
    .DEST_SYNC_FF(2),
    .INIT_SYNC_FF(1),
    .SIM_ASSERT_CHK(0),
    .SRC_INPUT_REG(1),
    .WIDTH(1)
  ) u_xpm (
    .src_clk(src_clk),
    .src_in(src_in),
    .dest_clk(dest_clk),
    .dest_out(dest_out)
  );
`else
  (* ASYNC_REG = "TRUE" *) logic meta, sync;
  always_ff @(posedge dest_clk) begin
    meta <= src_in;
    sync <= meta;
  end
  assign dest_out = sync;
`endif
endmodule

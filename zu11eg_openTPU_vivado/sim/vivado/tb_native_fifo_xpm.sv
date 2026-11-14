`timescale 1ns / 1ps

module xpm_fifo_stream_check #(
  parameter int W = 576,
  parameter int DEPTH = 64,
  parameter int N = 2000,
  parameter int SEED = 32'h1ace_b00c
) (
  input  logic wclk,
  input  logic rclk,
  input  logic sys_rst,
  output logic done
);
  logic        wrst;
  logic        rrst;
  logic        wvalid;
  logic        wready;
  logic [W-1:0] wdata;
  logic        rvalid;
  logic        rready;
  logic [W-1:0] rdata;
  int          errors;
  int          lfsr;
  logic        force_wrst;
  logic        force_rrst;

  otpu_native_fifo #(.W(W), .DEPTH(DEPTH), .MEMORY("block")) dut (
    .wclk(wclk), .wrst(wrst), .wvalid(wvalid), .wready(wready), .wdata(wdata),
    .rclk(rclk), .rrst(rrst), .rvalid(rvalid), .rready(rready), .rdata(rdata)
  );

  function automatic logic [W-1:0] make_word(input int seq);
    logic [W-1:0] value;
    value = {W{1'b0}};
    value[31:0] = seq;
    for (int i = 32; i < W; i += 32)
      value[i +: 32] = seq ^ (32'h9e37_79b9 * (i / 32));
    return value;
  endfunction

  function automatic bit next_ready(input int stride);
    lfsr = lfsr * 32'h1665_2d5b + 32'h9e37_79b9;
    return ((lfsr >> stride) & 3) != 0;
  endfunction

  task automatic wait_write_ready;
    int guard;
    begin
      guard = 0;
      while (!wready) begin
        @(posedge wclk);
        if (++guard > 10000) begin
          $fatal(1, "XPM FIFO width %0d did not leave write reset/full", W);
        end
      end
    end
  endtask

  task automatic flush_reset(input bit use_wreset, input bit use_rreset);
    begin
      @(negedge wclk);
      wvalid = 1'b0;
      rready = 1'b0;
      if (use_wreset)
        force_wrst = 1'b1;
      if (use_rreset)
        force_rrst = 1'b1;
      repeat (8) @(posedge wclk);
      @(negedge wclk);
      force_wrst = 1'b0;
      force_rrst = 1'b0;
      wait_write_ready();
      repeat (8) @(posedge rclk);
      if (rvalid)
        $fatal(1, "XPM FIFO width %0d retained data across reset", W);
    end
  endtask

  task automatic run_basic(input int base);
    int guard;
    begin
      fork
        begin
          for (int i = 0; i < N; i++) begin
            @(negedge wclk);
            wdata = make_word(base + i);
            wvalid = 1'b1;
            guard = 0;
            while (!wready) begin
              @(posedge wclk);
              if (++guard > 10000)
                $fatal(1, "XPM FIFO width %0d write timeout", W);
            end
            @(posedge wclk);
            @(negedge wclk);
            wvalid = 1'b0;
            repeat (next_ready(1) ? 3 : 0) @(posedge wclk);
          end
        end
        begin
          for (int i = 0; i < N; i++) begin
            guard = 0;
            @(negedge rclk);
            rready = next_ready(3);
            while (!(rvalid && rready)) begin
              @(posedge rclk);
              if (++guard > 10000)
                $fatal(1, "XPM FIFO width %0d read timeout", W);
              @(negedge rclk);
              rready = next_ready(3);
            end
            if (rdata !== make_word(base + i)) begin
              $error("XPM FIFO width %0d mismatch seq=%0d got=%h expected=%h",
                     W, base + i, rdata, make_word(base + i));
              errors++;
            end
            @(posedge rclk);
          end
        end
      join
      rready = 1'b0;
    end
  endtask

  assign wrst = sys_rst | force_wrst;
  assign rrst = sys_rst | force_rrst;

  initial begin
    wvalid = 1'b0;
    wdata = '0;
    rready = 1'b0;
    errors = 0;
    lfsr = SEED;
    done = 1'b0;
    force_wrst = 1'b0;
    force_rrst = 1'b0;

    wait (!sys_rst);
    wait_write_ready();
    run_basic(0);
    flush_reset(1'b1, 1'b0);
    run_basic(32'h10000);
    flush_reset(1'b0, 1'b1);
    run_basic(32'h20000);
    if (errors != 0)
      $fatal(1, "XPM FIFO width %0d errors=%0d", W, errors);
    $display("PASS xpm_fifo_stream_check W=%0d N=%0d", W, N);
    done = 1'b1;
  end
endmodule

module tb_native_fifo_xpm;
  logic wclk;
  logic rclk;
  logic sys_rst;
  logic done_576;
  logic done_514;

  always #5.0 wclk = ~wclk;
  always #1.6667 rclk = ~rclk;

  xpm_fifo_stream_check #(.W(576), .DEPTH(64), .N(2000), .SEED(32'h1ace_b00c))
    check_576 (.wclk, .rclk, .sys_rst, .done(done_576));

  xpm_fifo_stream_check #(.W(514), .DEPTH(128), .N(2000), .SEED(32'hc001_d00d))
    check_514 (.wclk, .rclk, .sys_rst, .done(done_514));

  initial begin
    wclk = 1'b0;
    rclk = 1'b0;
    sys_rst = 1'b1;
    #200;
    sys_rst = 1'b0;
  end

  initial begin
    #2_000_000;
    $fatal(1, "tb_native_fifo_xpm global timeout");
  end

  initial begin
    wait (done_576 && done_514);
    $display("PASS tb_native_fifo_xpm widths=576,514 reset=both-sides");
    $finish;
  end
endmodule

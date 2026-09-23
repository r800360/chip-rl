`timescale 1ns/1ps
module tb;
logic clk, rst_n, valid_i;
logic [63:0] a_i, b_i;
wire valid_o;
wire [6:0] y_o;
logic [6:0] last_y;
logic [63:0] rng;
popcount64_tree dut (.*);
initial clk = 1'b0;
always #5 clk = ~clk;
function automatic [63:0] next_rng(input [63:0] x);
  reg [63:0] t;
  begin
    t = x; t = t ^ (t << 13); t = t ^ (t >> 7); t = t ^ (t << 17);
    next_rng = t;
  end
endfunction

task automatic check(input [63:0] a, input [63:0] b);
  logic [6:0] expected;
  begin
    expected = $countones(a);
    @(negedge clk);
    a_i = a; b_i = b; valid_i = 1'b1;
    @(posedge clk); #1;
    if (valid_o !== 1'b1 || y_o !== expected)
      $fatal(1, "valid result mismatch: a=%h b=%h got=%h expected=%h", a,b,y_o,expected);
    last_y = expected;
    @(negedge clk);
    a_i = ~a; b_i = b ^ 64'ha55aa55aa55aa55a; valid_i = 1'b0;
    @(posedge clk); #1;
    if (valid_o !== 1'b0 || y_o !== last_y)
      $fatal(1, "invalid-cycle output was not held");
  end
endtask

task automatic back_to_back(input [63:0] a0, b0, a1, b1);
  logic [6:0] expected;
  begin
    @(negedge clk);
    a_i = a0; b_i = b0; valid_i = 1'b1;
    expected = $countones(a0);
    @(posedge clk); #1;
    if (valid_o !== 1'b1 || y_o !== expected)
      $fatal(1, "first back-to-back result failed");
    @(negedge clk);
    a_i = a1; b_i = b1; valid_i = 1'b1;
    expected = $countones(a1);
    @(posedge clk); #1;
    if (valid_o !== 1'b1 || y_o !== expected)
      $fatal(1, "second back-to-back result failed");
    last_y = expected;
  end
endtask

initial begin
  rst_n = 1'b0; valid_i = 1'b0; a_i = 0; b_i = 0;
  last_y = 7'd0; rng = 64'h243f6a8885a308d3;
  repeat (3) begin
    @(posedge clk); #1;
    if (valid_o !== 1'b0 || y_o !== 7'd0)
      $fatal(1, "reset protocol failed");
  end
  @(negedge clk); rst_n = 1'b1;
  check(64'h0000000000000000, 64'h0000000000000000);
  check(64'hffffffffffffffff, 64'h0000000000000001);
  check(64'h8000000000000000, 64'h7fffffffffffffff);
  check(64'h5555555555555555, 64'haaaaaaaaaaaaaaaa);
  check(64'h0000000000000001, 64'h0000000000000000);
  for (int i = 0; i < 10000; i = i + 1) begin
    rng = next_rng(rng); a_i = rng[63:0];
    rng = next_rng(rng); b_i = rng[63:0];
    check(a_i, b_i);
  end
  back_to_back(64'h0123456789abcdef, 64'hfedcba9876543210,
               64'h8000000000000001, 64'h0000000000000000);
  $display("PASS popcount64_tree randomized+protocol");
  $finish;
end
endmodule

`timescale 1ns/1ps
module tb;
logic clk, rst_n, valid_i;
logic [31:0] a_i, b_i;
wire valid_o;
wire [5:0] y_o;
logic [5:0] last_y;
logic [63:0] rng;
popcount32 dut (.*);
initial clk = 1'b0;
always #5 clk = ~clk;

function automatic [63:0] next_rng(input [63:0] x);
  reg [63:0] y;
  begin
    y = x; y = y ^ (y << 13);
    y = y ^ (y >> 7); y = y ^ (y << 17);
    next_rng = y;
  end
endfunction

task automatic check(input [31:0] a, input [31:0] b);
  logic [5:0] expected;
  begin
    expected = $countones(a);
    @(negedge clk);
    a_i = a; b_i = b; valid_i = 1'b1;
    @(posedge clk); #1;
    if (valid_o !== 1'b1 || y_o !== expected)
      $fatal(1, "valid result mismatch: a=%h b=%h got=%h expected=%h", a,b,y_o,expected);
    last_y = expected;
    @(negedge clk);
    a_i = ~a; b_i = b ^ 32'ha55aa55a; valid_i = 1'b0;
    @(posedge clk); #1;
    if (valid_o !== 1'b0 || y_o !== last_y)
      $fatal(1, "invalid-cycle output was not held");
  end
endtask

task automatic back_to_back(input [31:0] a0, b0, a1, b1);
  logic [5:0] expected;
  begin
    @(negedge clk);
    a_i = a0; b_i = b0; valid_i = 1'b1;
    // Distinct first result is checked using the same arithmetic oracle.
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
  last_y = 6'd0; rng = 64'h243f6a8885a308d3;
  repeat (3) begin
    @(posedge clk); #1;
    if (valid_o !== 1'b0 || y_o !== 6'd0)
      $fatal(1, "reset protocol failed");
  end
  @(negedge clk); rst_n = 1'b1;
  check(32'h00000000, 32'h00000000);
  check(32'hffffffff, 32'h00000001);
  check(32'h80000000, 32'h7fffffff);
  check(32'h55555555, 32'haaaaaaaa);
  check(32'h00000001, 32'h00000000);
  check(32'hffffffff, 32'hffffffff);
  for (int i = 0; i < 10000; i = i + 1) begin
    rng = next_rng(rng); a_i = rng[31:0];
    rng = next_rng(rng); b_i = rng[31:0];
    check(a_i, b_i);
  end
  back_to_back(32'h01234567,32'hfedcba98,32'h90000001,32'h00000000);
  $display("PASS popcount32 randomized+protocol");
  $finish;
end
endmodule

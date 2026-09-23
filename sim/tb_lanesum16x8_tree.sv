`timescale 1ns/1ps
module tb;
logic clk, rst_n, valid_i;
logic [63:0] a_i, b_i;
wire valid_o;
wire [11:0] y_o;
logic [11:0] last_y;
logic [63:0] rng;
lanesum16x8_tree dut (.*);
initial clk = 1'b0;
always #5 clk = ~clk;
function automatic [63:0] next_rng(input [63:0] x);
  reg [63:0] t;
  begin
    t = x; t = t ^ (t << 13); t = t ^ (t >> 7); t = t ^ (t << 17);
    next_rng = t;
  end
endfunction
function automatic [11:0] expected(input [63:0] a, input [63:0] b);
  logic [11:0] total;
  begin
    total = 12'd0;
    for (int i = 0; i < 8; i = i + 1) begin
      total = total + a[8*i +: 8];
      total = total + b[8*i +: 8];
    end
    expected = total;
  end
endfunction

task automatic check(input [63:0] a, input [63:0] b);
  logic [11:0] e;
  begin
    e = expected(a,b);
    @(negedge clk);
    a_i=a; b_i=b; valid_i=1'b1;
    @(posedge clk); #1;
    if (valid_o !== 1'b1 || y_o !== e)
      $fatal(1,"valid result mismatch: a=%h b=%h got=%h expected=%h",a,b,y_o,e);
    last_y=e;
    @(negedge clk);
    a_i=~a; b_i=~b; valid_i=1'b0;
    @(posedge clk); #1;
    if (valid_o !== 1'b0 || y_o !== last_y)
      $fatal(1,"invalid-cycle output was not held");
  end
endtask
initial begin
  rst_n=1'b0; valid_i=1'b0; a_i=0; b_i=0;
  last_y=12'd0; rng=64'h243f6a8885a308d3;
  repeat (3) begin
    @(posedge clk); #1;
    if (valid_o !== 1'b0 || y_o !== 12'd0)
      $fatal(1,"reset protocol failed");
  end
  @(negedge clk); rst_n=1'b1;
  check(64'h0000000000000000,64'h0000000000000000);
  check(64'hffffffffffffffff,64'hffffffffffffffff);
  check(64'h0101010101010101,64'h0101010101010101);
  check(64'h8000ff0000ff0080,64'h008000ff00ff8000);
  check(64'h0123456789abcdef,64'hfedcba9876543210);
  for (int i=0;i<10000;i=i+1) begin
    rng=next_rng(rng); a_i=rng;
    rng=next_rng(rng); b_i=rng;
    check(a_i,b_i);
  end
  // Back-to-back valid cycles, without an intervening invalid cycle.
  @(negedge clk); a_i=64'hffff0000ffff0000; b_i=64'h0000ffff0000ffff; valid_i=1'b1;
  @(posedge clk); #1;
  if (valid_o !== 1'b1 || y_o !== expected(a_i,b_i))
    $fatal(1,"back-to-back first cycle failed");
  @(negedge clk); a_i=64'h123456789abcdef0; b_i=64'hf0edcba987654321; valid_i=1'b1;
  @(posedge clk); #1;
  if (valid_o !== 1'b1 || y_o !== expected(a_i,b_i))
    $fatal(1,"back-to-back second cycle failed");
  $display("PASS lanesum16x8_tree randomized+protocol");
  $finish;
end
endmodule

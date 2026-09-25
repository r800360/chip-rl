module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
wire [31:0] l0 = ~a_i & b_i;
wire [31:0] e0 = ~(a_i ^ b_i);
wire [15:0] nl1, ne1;
wire [7:0]  l2, e2;
wire [3:0]  nl3, ne3;
wire [1:0]  l4, e4;
wire nlt;
genvar i;
generate
  for (i = 0; i < 16; i = i + 1) begin : L1
    assign nl1[i] = ~( l0[2*i+1] | (e0[2*i+1] & l0[2*i]) );
    assign ne1[i] = ~( e0[2*i+1] & e0[2*i] );
  end
  for (i = 0; i < 8; i = i + 1) begin : L2
    assign l2[i] = ~( nl1[2*i+1] & (ne1[2*i+1] | nl1[2*i]) );
    assign e2[i] = ~( ne1[2*i+1] | ne1[2*i] );
  end
  for (i = 0; i < 4; i = i + 1) begin : L3
    assign nl3[i] = ~( l2[2*i+1] | (e2[2*i+1] & l2[2*i]) );
    assign ne3[i] = ~( e2[2*i+1] & e2[2*i] );
  end
  for (i = 0; i < 2; i = i + 1) begin : L4
    assign l4[i] = ~( nl3[2*i+1] & (ne3[2*i+1] | nl3[2*i]) );
    assign e4[i] = ~( ne3[2*i+1] | ne3[2*i] );
  end
endgenerate
assign nlt = ~( l4[1] | (e4[1] & l4[0]) );

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        y_o <= ~( (nlt | ~valid_i) & ~(y_o & ~valid_i) );
    end
end
endmodule
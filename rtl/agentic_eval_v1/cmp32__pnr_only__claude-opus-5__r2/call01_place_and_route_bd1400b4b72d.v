module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire [31:0] eqb = ~(a_i ^ b_i);
wire [31:0] ltb = ~a_i & b_i;

wire [15:0] l1, e1;
wire [7:0]  l2, e2;
wire [3:0]  l3, e3;
wire [1:0]  l4;
wire        e4h;

genvar i;
generate
  for (i = 0; i < 16; i = i + 1) begin : g1
    assign l1[i] = eqb[2*i+1] ? ltb[2*i] : ltb[2*i+1];
    assign e1[i] = eqb[2*i+1] & eqb[2*i];
  end
  for (i = 0; i < 8; i = i + 1) begin : g2
    assign l2[i] = e1[2*i+1] ? l1[2*i] : l1[2*i+1];
    assign e2[i] = e1[2*i+1] & e1[2*i];
  end
  for (i = 0; i < 4; i = i + 1) begin : g3
    assign l3[i] = e2[2*i+1] ? l2[2*i] : l2[2*i+1];
    assign e3[i] = e2[2*i+1] & e2[2*i];
  end
  for (i = 0; i < 2; i = i + 1) begin : g4
    assign l4[i] = e3[2*i+1] ? l3[2*i] : l3[2*i+1];
  end
endgenerate

assign e4h = e3[3] & e3[2];

wire cmp_0 = e4h ? l4[0] : l4[1];

wire sel  = rst_n & valid_i;
wire hold = rst_n & y_o[0];

always @(posedge clk) begin
    valid_o <= rst_n & valid_i;
    y_o <= sel ? cmp_0 : hold;
end
endmodule

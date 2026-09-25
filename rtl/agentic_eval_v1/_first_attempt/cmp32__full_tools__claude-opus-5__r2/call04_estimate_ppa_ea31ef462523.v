module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
wire [31:0] x  = a_i ^ b_i;
wire [31:0] lt = ~a_i & b_i;

wire [15:0] L1, X1;
wire [7:0]  L2, X2;
wire [3:0]  L3, X3;
wire [1:0]  L4, X4;
wire        L5;
genvar i;
generate
  for (i = 0; i < 16; i = i + 1) begin : G1
    assign L1[i] = x[2*i+1] ? b_i[2*i+1] : lt[2*i];
    assign X1[i] = x[2*i+1] | x[2*i];
  end
  for (i = 0; i < 8; i = i + 1) begin : G2
    assign L2[i] = X1[2*i+1] ? L1[2*i+1] : L1[2*i];
    assign X2[i] = X1[2*i+1] | X1[2*i];
  end
  for (i = 0; i < 4; i = i + 1) begin : G3
    assign L3[i] = X2[2*i+1] ? L2[2*i+1] : L2[2*i];
    assign X3[i] = X2[2*i+1] | X2[2*i];
  end
  for (i = 0; i < 2; i = i + 1) begin : G4
    assign L4[i] = X3[2*i+1] ? L3[2*i+1] : L3[2*i];
    assign X4[i] = X3[2*i+1] | X3[2*i];
  end
endgenerate
assign L5 = X4[1] ? L4[1] : L4[0];

wire sel  = rst_n & valid_i;
wire hold = rst_n & y_o;
always @(posedge clk) begin
    valid_o <= rst_n & valid_i;
    y_o <= sel ? L5 : hold;
end
endmodule
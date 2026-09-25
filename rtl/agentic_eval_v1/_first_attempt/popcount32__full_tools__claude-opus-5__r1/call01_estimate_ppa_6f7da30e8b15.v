module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
function [1:0] FAF;
  input x, y, z;
  FAF = {(x&y)|(x&z)|(y&z), x^y^z};
endfunction
function [1:0] HAF;
  input x, y;
  HAF = {x&y, x^y};
endfunction

wire [1:0] f1 [0:9];
genvar i;
generate
  for (i=0;i<10;i=i+1) begin : L1
    assign f1[i] = FAF(a_i[3*i], a_i[3*i+1], a_i[3*i+2]);
  end
endgenerate

wire [1:0] f20 = FAF(a_i[30], a_i[31], f1[0][0]);
wire [1:0] f21 = FAF(f1[1][0], f1[2][0], f1[3][0]);
wire [1:0] f22 = FAF(f1[4][0], f1[5][0], f1[6][0]);
wire [1:0] f23 = FAF(f1[7][0], f1[8][0], f1[9][0]);
wire [1:0] f30 = FAF(f20[0], f21[0], f22[0]);
wire [1:0] h40 = HAF(f30[0], f23[0]);

wire [1:0] g0 = FAF(f1[0][1], f1[1][1], f1[2][1]);
wire [1:0] g1 = FAF(f1[3][1], f1[4][1], f1[5][1]);
wire [1:0] g2 = FAF(f1[6][1], f1[7][1], f1[8][1]);
wire [1:0] g3 = FAF(f1[9][1], g0[0], g1[0]);
wire [1:0] g4 = FAF(g2[0], f20[1], f21[1]);
wire [1:0] g5 = FAF(f22[1], f23[1], f30[1]);
wire [1:0] g6 = FAF(g3[0], g4[0], g5[0]);
wire [1:0] h1 = HAF(g6[0], h40[1]);

wire [1:0] k0 = FAF(g0[1], g1[1], g2[1]);
wire [1:0] k1 = FAF(g3[1], g4[1], k0[0]);
wire [1:0] k2 = FAF(k1[0], g5[1], g6[1]);
wire [1:0] h2 = HAF(k2[0], h1[1]);

wire [1:0] p0 = FAF(k0[1], k1[1], k2[1]);
wire [1:0] h3 = HAF(p0[0], h2[1]);

wire [1:0] h4 = HAF(p0[1], h3[1]);

wire [5:0] tot = {h4[1], h4[0], h3[0], h2[0], h1[0], h40[0]};

always @(posedge clk) begin
  if (!rst_n) begin
    valid_o <= 1'b0;
    y_o <= 6'd0;
  end else begin
    valid_o <= valid_i;
    if (valid_i) y_o <= tot;
  end
end
endmodule
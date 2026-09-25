module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

// per-bit difference
wire [31:0] x = a_i ^ b_i;

// "not equal" trees over aligned groups
wire [15:0] ne1;
wire [7:0]  ne2;
wire [3:0]  ne3;
wire [1:0]  ne4;

// conditional less-than of a group, valid only when that group differs
wire [15:0] G1;
wire [7:0]  G2;
wire [3:0]  G3;
wire [1:0]  G4;

genvar i;
generate
  for (i = 0; i < 16; i = i + 1) begin : lv1
    assign ne1[i] = x[2*i+1] | x[2*i];
    assign G1[i]  = x[2*i+1] ? b_i[2*i+1] : b_i[2*i];
  end
  for (i = 0; i < 8; i = i + 1) begin : lv2
    assign ne2[i] = ne1[2*i+1] | ne1[2*i];
    assign G2[i]  = ne1[2*i+1] ? G1[2*i+1] : G1[2*i];
  end
  for (i = 0; i < 4; i = i + 1) begin : lv3
    assign ne3[i] = ne2[2*i+1] | ne2[2*i];
    assign G3[i]  = ne2[2*i+1] ? G2[2*i+1] : G2[2*i];
  end
  for (i = 0; i < 2; i = i + 1) begin : lv4
    assign ne4[i] = ne3[2*i+1] | ne3[2*i];
    assign G4[i]  = ne3[2*i+1] ? G3[2*i+1] : G3[2*i];
  end
endgenerate

// exact less-than chain, each select arriving just in time
wire h0  = x[0] & b_i[0];
wire h1  = x[1]   ? b_i[1] : h0;
wire h3  = ne1[1] ? G1[1]  : h1;
wire h7  = ne2[1] ? G2[1]  : h3;
wire h15 = ne3[1] ? G3[1]  : h7;
wire cmp = ne4[1] ? G4[1]  : h15;

wire en   = rst_n & valid_i;
wire hold = rst_n & y_o;

always @(posedge clk) begin
    valid_o <= en;
    y_o     <= en ? cmp : hold;
end
endmodule
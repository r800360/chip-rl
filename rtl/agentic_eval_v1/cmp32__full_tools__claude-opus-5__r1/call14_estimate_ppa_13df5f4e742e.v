module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
    wire [31:0] p = ~(a_i ^ b_i);
    wire [31:0] g = ~a_i & b_i;

    wire [15:0] G2, P2;
    wire [4:0]  PPh;
    genvar j;
    generate
      for (j=0;j<16;j=j+1) begin : l2
        assign G2[j] = g[2*j+1] | (p[2*j+1] & g[2*j]);
        assign P2[j] = p[2*j+1] & p[2*j];
      end
      for (j=0;j<5;j=j+1) begin : lpp
        assign PPh[j] = &p[6*j+7 -: 4];
      end
    endgenerate

    wire [4:0] G6, P6;
    generate
      for (j=0;j<5;j=j+1) begin : l3
        assign G6[j] = G2[3*j+3] | (P2[3*j+3] & G2[3*j+2]) | (PPh[j] & G2[3*j+1]);
        assign P6[j] = PPh[j] & P2[3*j+1];
      end
    endgenerate

    wire P12X = &p[31:20];
    wire P12Y = &p[13:2];
    wire P18X = &p[31:14];

    wire G_X = G6[4] | (P6[4] & G6[3]) | (P12X & G6[2]);
    wire G_Y = G6[1] | (P6[1] & G6[0]) | (P12Y & G2[0]);
    wire LT  = G_X | (P18X & G_Y);

    wire en = valid_i & rst_n;
    always @(posedge clk) begin
        valid_o <= valid_i & rst_n;
        y_o <= en ? LT : (y_o & rst_n);
    end
endmodule

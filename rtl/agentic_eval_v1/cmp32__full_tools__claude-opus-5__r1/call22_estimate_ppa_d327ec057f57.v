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
    genvar j;
    generate
      for (j=0;j<16;j=j+1) begin : l2
        assign G2[j] = g[2*j+1] | (p[2*j+1] & g[2*j]);
        assign P2[j] = p[2*j+1] & p[2*j];
      end
    endgenerate

    wire [4:0] PP;
    generate
      for (j=0;j<5;j=j+1) begin : lpp
        assign PP[j] = &p[6*j+5 -: 4];
      end
    endgenerate

    wire [4:0] G6, P6;
    generate
      for (j=0;j<5;j=j+1) begin : l3
        assign G6[j] = G2[3*j+2] | (P2[3*j+2] & G2[3*j+1]) | (PP[j] & G2[3*j]);
        assign P6[j] = PP[j] & P2[3*j];
      end
    endgenerate

    wire P8hi  = &p[31:24];
    wire P12Y  = &p[17:6];
    wire P14X  = &p[31:18];

    wire G_X = G2[15] | (P2[15] & G6[4]) | (P8hi & G6[3]);
    wire G_Y = G6[2]  | (P6[2]  & G6[1]) | (P12Y & G6[0]);
    wire LT  = G_X | (P14X & G_Y);

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o <= 1'd0;
        end else begin
            valid_o <= valid_i;
            if (valid_i) y_o <= LT;
        end
    end
endmodule

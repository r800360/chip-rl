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
    wire [4:0]  PP;
    genvar j;
    generate
      for (j=0;j<16;j=j+1) begin : l2
        assign G2[j] = g[2*j+1] | (p[2*j+1] & g[2*j]);
        assign P2[j] = p[2*j+1] & p[2*j];
      end
      for (j=0;j<5;j=j+1) begin : lpp
        assign PP[j] = &p[6*j+5 -: 4];
      end
    endgenerate

    // level 3 : 6-bit nodes, bits 6j+5..6j
    wire [4:0] G6, P6;
    generate
      for (j=0;j<5;j=j+1) begin : l3
        assign G6[j] = G2[3*j+2] | (P2[3*j+2] & G2[3*j+1]) | (PP[j] & G2[3*j]);
        assign P6[j] = PP[j] & P2[3*j];
      end
    endgenerate

    // level 4 : 12-bit nodes (radix 2)
    wire G12a = G6[3] | (P6[3] & G6[2]);        // bits 23..12
    wire G12b = G6[1] | (P6[1] & G6[0]);        // bits 11..0
    wire G8t  = G2[15] | (P2[15] & G6[4]);      // bits 31..24
    wire P8t  = P2[15] & PP[4] & P2[12];        // p[31:24]
    wire P20  = P8t & P6[3] & P6[2];            // p[31:12]

    wire LT = G8t | (P8t & G12a) | (P20 & G12b);

    wire en = valid_i & rst_n;
    always @(posedge clk) begin
        valid_o <= valid_i & rst_n;
        y_o <= en ? LT : (y_o & rst_n);
    end
endmodule

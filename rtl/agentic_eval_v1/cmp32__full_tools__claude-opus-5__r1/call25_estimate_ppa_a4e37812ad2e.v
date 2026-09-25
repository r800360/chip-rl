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
    wire [7:0]  G4, P4;
    wire [3:0]  P8;
    genvar j;
    generate
      for (j=0;j<16;j=j+1) begin : l2
        assign G2[j] = g[2*j+1] | (p[2*j+1] & g[2*j]);
        assign P2[j] = p[2*j+1] & p[2*j];
      end
      for (j=0;j<8;j=j+1) begin : l3
        assign G4[j] = G2[2*j+1] | (P2[2*j+1] & G2[2*j]);
        assign P4[j] = P2[2*j+1] & P2[2*j];
      end
      for (j=0;j<4;j=j+1) begin : l3b
        assign P8[j] = P2[4*j+3] & P2[4*j+2] & P2[4*j+1] & P2[4*j];
      end
    endgenerate

    wire P8c = P2[5] & P2[4] & P2[3] & P2[2];      // p[11:4]

    wire G_A = G4[7] | (P4[7] & G4[6]);                                 // bits 31..24
    wire G_B = G4[5] | (P4[5] & G4[4]) | (P8[2] & G4[3]);               // bits 23..12
    wire G_C = G4[2] | (P4[2] & G4[1]) | (P8c  & G4[0]);                // bits 11..0
    wire PA  = P8[3];                                                   // p[31:24]
    wire PQ  = P8[3] & P8[2] & P2[7] & P2[6];                           // p[31:12]

    wire LT  = G_A | (PA & G_B) | (PQ & G_C);

    wire en = valid_i & rst_n;
    always @(posedge clk) begin
        valid_o <= valid_i & rst_n;
        y_o <= en ? LT : (y_o & rst_n);
    end
endmodule

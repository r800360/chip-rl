module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
    wire [31:0] g = ~a_i & b_i;
    wire [31:0] p = ~(a_i ^ b_i);

    wire [7:0] G1, P1;
    wire [1:0] G2, P2;
    wire       G3;

    genvar i;
    generate
      for (i=0;i<8;i=i+1) begin : l1
        assign G1[i] = g[4*i+3] | (p[4*i+3] & (g[4*i+2] | (p[4*i+2] & (g[4*i+1] | (p[4*i+1] & g[4*i])))));
        assign P1[i] = p[4*i+3] & p[4*i+2] & p[4*i+1] & p[4*i];
      end
      for (i=0;i<2;i=i+1) begin : l2
        assign G2[i] = G1[4*i+3] | (P1[4*i+3] & (G1[4*i+2] | (P1[4*i+2] & (G1[4*i+1] | (P1[4*i+1] & G1[4*i])))));
        assign P2[i] = P1[4*i+3] & P1[4*i+2] & P1[4*i+1] & P1[4*i];
      end
    endgenerate
    assign G3 = G2[1] | (P2[1] & G2[0]);

    wire en = valid_i & rst_n;
    always @(posedge clk) begin
        valid_o <= valid_i & rst_n;
        y_o <= en ? G3 : (y_o & rst_n);
    end
endmodule

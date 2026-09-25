module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
    wire [31:0] g0 = ~a_i & b_i;
    wire [31:0] p0 = ~(a_i ^ b_i);

    wire [15:0] g1, p1;
    wire [7:0]  g2, p2;
    wire [3:0]  g3, p3;
    wire [1:0]  g4, p4;
    wire        g5;

    genvar i;
    generate
      for (i=0;i<16;i=i+1) begin : l1
        assign g1[i] = g0[2*i+1] | (p0[2*i+1] & g0[2*i]);
        assign p1[i] = p0[2*i+1] & p0[2*i];
      end
      for (i=0;i<8;i=i+1) begin : l2
        assign g2[i] = g1[2*i+1] | (p1[2*i+1] & g1[2*i]);
        assign p2[i] = p1[2*i+1] & p1[2*i];
      end
      for (i=0;i<4;i=i+1) begin : l3
        assign g3[i] = g2[2*i+1] | (p2[2*i+1] & g2[2*i]);
        assign p3[i] = p2[2*i+1] & p2[2*i];
      end
      for (i=0;i<2;i=i+1) begin : l4
        assign g4[i] = g3[2*i+1] | (p3[2*i+1] & g3[2*i]);
        assign p4[i] = p3[2*i+1] & p3[2*i];
      end
    endgenerate

    assign g5 = g4[1] | (p4[1] & g4[0]);

    wire en = valid_i & rst_n;

    always @(posedge clk) begin
        valid_o <= valid_i & rst_n;
        y_o <= en ? g5 : (y_o & rst_n);
    end
endmodule

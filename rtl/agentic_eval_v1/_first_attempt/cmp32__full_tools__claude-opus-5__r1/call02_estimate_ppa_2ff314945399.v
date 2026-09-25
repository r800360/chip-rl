module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
    wire [31:0] e = ~(a_i ^ b_i);
    wire [31:0] l = ~a_i & b_i;

    wire [15:0] l1, e1;
    wire [7:0]  l2, e2;
    wire [3:0]  l3, e3;
    wire [1:0]  l4, e4;
    wire        l5;

    genvar i;
    generate
      for (i=0;i<16;i=i+1) begin : g1
        assign l1[i] = l[2*i+1] | (e[2*i+1] & l[2*i]);
        assign e1[i] = e[2*i+1] & e[2*i];
      end
      for (i=0;i<8;i=i+1) begin : g2
        assign l2[i] = l1[2*i+1] | (e1[2*i+1] & l1[2*i]);
        assign e2[i] = e1[2*i+1] & e1[2*i];
      end
      for (i=0;i<4;i=i+1) begin : g3
        assign l3[i] = l2[2*i+1] | (e2[2*i+1] & l2[2*i]);
        assign e3[i] = e2[2*i+1] & e2[2*i];
      end
      for (i=0;i<2;i=i+1) begin : g4
        assign l4[i] = l3[2*i+1] | (e3[2*i+1] & l3[2*i]);
        assign e4[i] = e3[2*i+1] & e3[2*i];
      end
    endgenerate

    assign l5 = l4[1] | (e4[1] & l4[0]);

    wire sel  = valid_i & rst_n;
    wire hold = y_o & rst_n;

    always @(posedge clk) begin
        valid_o <= sel;
        y_o     <= sel ? l5 : hold;
    end
endmodule
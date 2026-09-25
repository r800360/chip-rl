module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
    // alternating-polarity prefix tree
    wire [31:0] ln = a_i | ~b_i;      // ~(a<b) per bit
    wire [31:0] en = a_i ^ b_i;       // ~(a==b) per bit

    wire [15:0] l1, e1;   // true polarity
    wire [7:0]  l2n, e2n; // inverted
    wire [3:0]  l3, e3;
    wire [1:0]  l4n, e4n;
    wire        l5;
    genvar i;
    generate
      for (i=0;i<16;i=i+1) begin : g1
        assign l1[i] = ~(ln[2*i+1] & (en[2*i+1] | ln[2*i]));
        assign e1[i] = ~(en[2*i+1] | en[2*i]);
      end
      for (i=0;i<8;i=i+1) begin : g2
        assign l2n[i] = ~(l1[2*i+1] | (e1[2*i+1] & l1[2*i]));
        assign e2n[i] = ~(e1[2*i+1] & e1[2*i]);
      end
      for (i=0;i<4;i=i+1) begin : g3
        assign l3[i] = ~(l2n[2*i+1] & (e2n[2*i+1] | l2n[2*i]));
        assign e3[i] = ~(e2n[2*i+1] | e2n[2*i]);
      end
      for (i=0;i<2;i=i+1) begin : g4
        assign l4n[i] = ~(l3[2*i+1] | (e3[2*i+1] & l3[2*i]));
        assign e4n[i] = ~(e3[2*i+1] & e3[2*i]);
      end
    endgenerate
    assign l5 = ~(l4n[1] & (e4n[1] | l4n[0]));

    wire sel  = valid_i & rst_n;
    wire hold = y_o & rst_n;
    always @(posedge clk) begin
        valid_o <= sel;
        y_o     <= sel ? l5 : hold;
    end
endmodule
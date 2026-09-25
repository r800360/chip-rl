module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

// bit-level less-than / equal
wire [31:0] l0 = ~a_i & b_i;
wire [31:0] e0 = ~(a_i ^ b_i);

wire [15:0] l1, e1;
wire [7:0]  l2, e2;
wire [3:0]  l3, e3;
wire [1:0]  l4, e4;

genvar i;
generate
  for (i = 0; i < 16; i = i + 1) begin : g1
    assign l1[i] = l0[2*i+1] | (e0[2*i+1] & l0[2*i]);
    assign e1[i] = e0[2*i+1] & e0[2*i];
  end
  for (i = 0; i < 8; i = i + 1) begin : g2
    assign l2[i] = l1[2*i+1] | (e1[2*i+1] & l1[2*i]);
    assign e2[i] = e1[2*i+1] & e1[2*i];
  end
  for (i = 0; i < 4; i = i + 1) begin : g3
    assign l3[i] = l2[2*i+1] | (e2[2*i+1] & l2[2*i]);
    assign e3[i] = e2[2*i+1] & e2[2*i];
  end
  for (i = 0; i < 2; i = i + 1) begin : g4
    assign l4[i] = l3[2*i+1] | (e3[2*i+1] & l3[2*i]);
    assign e4[i] = e3[2*i+1] & e3[2*i];
  end
endgenerate

wire cmp_0 = l4[1] | (e4[1] & l4[0]);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= cmp_0;
    end
end
endmodule

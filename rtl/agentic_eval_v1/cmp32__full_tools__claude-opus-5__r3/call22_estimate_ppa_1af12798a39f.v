module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
wire [15:0] lg, eg;
wire [7:0]  l1, e1;
wire [3:0]  l2, e2;
wire [1:0]  l3, e3;
genvar i;
generate
  for (i = 0; i < 16; i = i + 1) begin : G
    assign lg[i] = a_i[2*i+1 -: 2] <  b_i[2*i+1 -: 2];
    assign eg[i] = a_i[2*i+1 -: 2] == b_i[2*i+1 -: 2];
  end
  for (i = 0; i < 8; i = i + 1) begin : L1
    assign l1[i] = lg[2*i+1] | (eg[2*i+1] & lg[2*i]);
    assign e1[i] = eg[2*i+1] & eg[2*i];
  end
  for (i = 0; i < 4; i = i + 1) begin : L2
    assign l2[i] = l1[2*i+1] | (e1[2*i+1] & l1[2*i]);
    assign e2[i] = e1[2*i+1] & e1[2*i];
  end
  for (i = 0; i < 2; i = i + 1) begin : L3
    assign l3[i] = l2[2*i+1] | (e2[2*i+1] & l2[2*i]);
    assign e3[i] = e2[2*i+1] & e2[2*i];
  end
endgenerate
wire lt = l3[1] | (e3[1] & l3[0]);
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= lt;
    end
end
endmodule
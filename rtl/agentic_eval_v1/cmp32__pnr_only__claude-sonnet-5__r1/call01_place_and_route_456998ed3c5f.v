module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire [31:0] eq_l0 = ~(a_i ^ b_i);
wire [31:0] lt_l0 = (~a_i) & b_i;

wire [15:0] eq_l1, lt_l1;
genvar i;
generate
  for (i=0;i<16;i=i+1) begin: L1
    assign eq_l1[i] = eq_l0[2*i+1] & eq_l0[2*i];
    assign lt_l1[i] = lt_l0[2*i+1] | (eq_l0[2*i+1] & lt_l0[2*i]);
  end
endgenerate

wire [7:0] eq_l2, lt_l2;
generate
  for (i=0;i<8;i=i+1) begin: L2
    assign eq_l2[i] = eq_l1[2*i+1] & eq_l1[2*i];
    assign lt_l2[i] = lt_l1[2*i+1] | (eq_l1[2*i+1] & lt_l1[2*i]);
  end
endgenerate

wire [3:0] eq_l3, lt_l3;
generate
  for (i=0;i<4;i=i+1) begin: L3
    assign eq_l3[i] = eq_l2[2*i+1] & eq_l2[2*i];
    assign lt_l3[i] = lt_l2[2*i+1] | (eq_l2[2*i+1] & lt_l2[2*i]);
  end
endgenerate

wire [1:0] eq_l4, lt_l4;
generate
  for (i=0;i<2;i=i+1) begin: L4
    assign eq_l4[i] = eq_l3[2*i+1] & eq_l3[2*i];
    assign lt_l4[i] = lt_l3[2*i+1] | (eq_l3[2*i+1] & lt_l3[2*i]);
  end
endgenerate

wire eq_l5, lt_l5;
assign eq_l5 = eq_l4[1] & eq_l4[0];
assign lt_l5 = lt_l4[1] | (eq_l4[1] & lt_l4[0]);

wire cmp_0 = lt_l5;

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

module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [7:0] l1, l0, v4b;
genvar g;
generate
for (g = 0; g < 8; g = g + 1) begin : L0
  assign l1[g]  = a_i[4*g+3] | a_i[4*g+2];
  assign l0[g]  = l1[g] ? a_i[4*g+3] : a_i[4*g+1];
  assign v4b[g] = l1[g] | a_i[4*g+1] | a_i[4*g+0];
end
endgenerate
wire [3:0] v8, m2, m1, m0;
generate
for (g = 0; g < 4; g = g + 1) begin : L1
  assign v8[g] = v4b[2*g+1] | v4b[2*g];
  assign m2[g] = v4b[2*g+1];
  assign m1[g] = v4b[2*g+1] ? l1[2*g+1] : l1[2*g];
  assign m0[g] = v4b[2*g+1] ? l0[2*g+1] : l0[2*g];
end
endgenerate
wire [1:0] v16, n3, n2, n1, n0;
generate
for (g = 0; g < 2; g = g + 1) begin : L2
  assign v16[g] = v8[2*g+1] | v8[2*g];
  assign n3[g] = v8[2*g+1];
  assign n2[g] = v8[2*g+1] ? m2[2*g+1] : m2[2*g];
  assign n1[g] = v8[2*g+1] ? m1[2*g+1] : m1[2*g];
  assign n0[g] = v8[2*g+1] ? m0[2*g+1] : m0[2*g];
end
endgenerate
wire hit = v16[1] | v16[0];
wire [5:0] chosen_0 = {hit, v16[1],
                       v16[1] ? n3[1] : n3[0],
                       v16[1] ? n2[1] : n2[0],
                       v16[1] ? n1[1] : n1[0],
                       v16[1] ? n0[1] : n0[0]};
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen_0;
    end
end
endmodule

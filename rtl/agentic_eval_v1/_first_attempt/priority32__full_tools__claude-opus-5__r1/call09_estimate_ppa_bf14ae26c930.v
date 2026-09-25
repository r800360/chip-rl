module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// binary mux tree, 4-bit leaves computed with AOI-friendly forms
wire [7:0] v4b;     // |a[4g+3:4g]
wire [7:0] l1, l0;  // 2-bit index in each 4-bit group
genvar g;
generate
for (g = 0; g < 8; g = g + 1) begin : L0
  assign v4b[g] = |a_i[4*g +: 4];
  assign l1[g]  = a_i[4*g+3] | a_i[4*g+2];
  assign l0[g]  = a_i[4*g+3] | (~a_i[4*g+2] & a_i[4*g+1]);
end
endgenerate

// combine pairs of 4-bit groups -> 8-bit groups (3-bit index)
wire [3:0] v8;
wire [3:0] m2, m1, m0;
generate
for (g = 0; g < 4; g = g + 1) begin : L1
  assign v8[g] = |a_i[8*g +: 8];
  assign m2[g] = v4b[2*g+1];
  assign m1[g] = v4b[2*g+1] ? l1[2*g+1] : l1[2*g];
  assign m0[g] = v4b[2*g+1] ? l0[2*g+1] : l0[2*g];
end
endgenerate

// combine -> 16-bit groups (4-bit index)
wire [1:0] v16;
wire [1:0] n3, n2, n1, n0;
generate
for (g = 0; g < 2; g = g + 1) begin : L2
  assign v16[g] = |a_i[16*g +: 16];
  assign n3[g] = v8[2*g+1];
  assign n2[g] = v8[2*g+1] ? m2[2*g+1] : m2[2*g];
  assign n1[g] = v8[2*g+1] ? m1[2*g+1] : m1[2*g];
  assign n0[g] = v8[2*g+1] ? m0[2*g+1] : m0[2*g];
end
endgenerate

wire hit = |a_i;
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

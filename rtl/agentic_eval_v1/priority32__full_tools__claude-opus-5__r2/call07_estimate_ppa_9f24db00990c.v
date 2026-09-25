module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// bottom-up parallel tree
wire [15:0] h1;
wire [15:0] i0;
genvar g;
generate
for (g = 0; g < 16; g = g + 1) begin : lvl1
    assign h1[g] = a_i[2*g+1] | a_i[2*g];
    assign i0[g] = a_i[2*g+1];
end
endgenerate
wire [7:0] h2;
wire [7:0] q1, q0;
generate
for (g = 0; g < 8; g = g + 1) begin : lvl2
    assign h2[g] = h1[2*g+1] | h1[2*g];
    assign q1[g] = h1[2*g+1];
    assign q0[g] = h1[2*g+1] ? i0[2*g+1] : i0[2*g];
end
endgenerate
wire [3:0] h3;
wire [3:0] r2, r1, r0;
generate
for (g = 0; g < 4; g = g + 1) begin : lvl3
    assign h3[g] = h2[2*g+1] | h2[2*g];
    assign r2[g] = h2[2*g+1];
    assign r1[g] = h2[2*g+1] ? q1[2*g+1] : q1[2*g];
    assign r0[g] = h2[2*g+1] ? q0[2*g+1] : q0[2*g];
end
endgenerate
wire [1:0] h4;
wire [1:0] t3, t2, t1, t0;
generate
for (g = 0; g < 2; g = g + 1) begin : lvl4
    assign h4[g] = h3[2*g+1] | h3[2*g];
    assign t3[g] = h3[2*g+1];
    assign t2[g] = h3[2*g+1] ? r2[2*g+1] : r2[2*g];
    assign t1[g] = h3[2*g+1] ? r1[2*g+1] : r1[2*g];
    assign t0[g] = h3[2*g+1] ? r0[2*g+1] : r0[2*g];
end
endgenerate
wire hit = h4[1] | h4[0];
wire y4 = h4[1];
wire y3 = h4[1] ? t3[1] : t3[0];
wire y2 = h4[1] ? t2[1] : t2[0];
wire y1 = h4[1] ? t1[1] : t1[0];
wire y0 = h4[1] ? t0[1] : t0[0];
wire [5:0] chosen = {hit, y4, y3, y2, y1, y0};
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen;
    end
end
endmodule
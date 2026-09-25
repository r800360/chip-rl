module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
wire [7:0] gl, ge;
genvar i;
generate
for (i = 0; i < 8; i = i + 1) begin : g
  assign gl[i] = (a_i[4*i+3 -: 4] < b_i[4*i+3 -: 4]);
  assign ge[i] = (a_i[4*i+3 -: 4] == b_i[4*i+3 -: 4]);
end
endgenerate
wire [3:0] l1, e1;
generate
for (i = 0; i < 4; i = i + 1) begin : s1
  assign l1[i] = gl[2*i+1] | (ge[2*i+1] & gl[2*i]);
  assign e1[i] = ge[2*i+1] & ge[2*i];
end
endgenerate
wire [1:0] l2, e2;
generate
for (i = 0; i < 2; i = i + 1) begin : s2
  assign l2[i] = l1[2*i+1] | (e1[2*i+1] & l1[2*i]);
  assign e2[i] = e1[2*i+1] & e1[2*i];
end
endgenerate
wire cmp_0 = l2[1] | (e2[1] & l2[0]);
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
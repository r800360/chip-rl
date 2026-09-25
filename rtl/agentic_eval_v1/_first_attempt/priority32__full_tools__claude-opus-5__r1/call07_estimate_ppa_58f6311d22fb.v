module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// 4 groups of 8 bits
wire [3:0] v8;
wire [3:0] q2, q1, q0;
genvar g;
generate
for (g = 0; g < 4; g = g + 1) begin : L0
  wire [7:0] x = a_i[8*g +: 8];
  wire hi = |x[7:4];
  assign v8[g] = |x;
  assign q2[g] = hi;
  assign q1[g] = hi ? (x[7]|x[6]) : (x[3]|x[2]);
  assign q0[g] = hi ? (x[7] | (~x[6] & x[5])) : (x[3] | (~x[2] & x[1]));
end
endgenerate

wire hit = |a_i;
wire y4 = v8[3] | v8[2];
wire y3 = v8[3] | (~v8[2] & v8[1]);
wire [2:0] low = v8[3] ? {q2[3],q1[3],q0[3]} :
                 v8[2] ? {q2[2],q1[2],q0[2]} :
                 v8[1] ? {q2[1],q1[1],q0[1]} :
                         {q2[0],q1[0],q0[0]};

wire [5:0] chosen_0 = {hit, y4, y3, low};

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

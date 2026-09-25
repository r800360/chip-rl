module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// 8 groups of 4 bits, flat one-hot selection
wire [7:0] v;           // group non-empty
wire [7:0] p1, p0;      // within-group index bits
genvar g;
generate
for (g = 0; g < 8; g = g + 1) begin : L0
  assign v[g]  = |a_i[4*g +: 4];
  assign p1[g] = a_i[4*g+3] | a_i[4*g+2];
  assign p0[g] = a_i[4*g+3] | (a_i[4*g+1] & ~a_i[4*g+2]);
end
endgenerate

wire [7:0] s;
assign s[7] = v[7];
assign s[6] = v[6] & ~v[7];
assign s[5] = v[5] & ~(v[7]|v[6]);
assign s[4] = v[4] & ~(v[7]|v[6]|v[5]);
assign s[3] = v[3] & ~(v[7]|v[6]|v[5]|v[4]);
assign s[2] = v[2] & ~(v[7]|v[6]|v[5]|v[4]|v[3]);
assign s[1] = v[1] & ~(v[7]|v[6]|v[5]|v[4]|v[3]|v[2]);
assign s[0] = v[0] & ~(v[7]|v[6]|v[5]|v[4]|v[3]|v[2]|v[1]);

wire hit = |a_i;
wire y4 = |a_i[31:16];
wire y3 = (v[7]|v[6]) | (~(v[7]|v[6]|v[5]|v[4]) & (v[3]|v[2]));
wire y2 = s[7]|s[6]|s[5]|s[4]|s[3]|s[2];  // wrong-> replaced below
wire y2b = (v[7]) | (~v[7]&~v[6]&v[5]) | (~v[7]&~v[6]&~v[5]&~v[4]&v[3]) | (~v[7]&~v[6]&~v[5]&~v[4]&~v[3]&~v[2]&v[1]);
wire y1 = (s[7]&p1[7])|(s[6]&p1[6])|(s[5]&p1[5])|(s[4]&p1[4])|
          (s[3]&p1[3])|(s[2]&p1[2])|(s[1]&p1[1])|(s[0]&p1[0]);
wire y0 = (s[7]&p0[7])|(s[6]&p0[6])|(s[5]&p0[5])|(s[4]&p0[4])|
          (s[3]&p0[3])|(s[2]&p0[2])|(s[1]&p0[1])|(s[0]&p0[0]);

wire [5:0] chosen_0 = {hit, y4, y3, y2b, y1, y0};

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

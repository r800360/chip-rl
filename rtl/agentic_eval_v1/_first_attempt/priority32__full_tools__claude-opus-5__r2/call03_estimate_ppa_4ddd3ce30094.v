module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// byte-level decomposition
wire b0 = |a_i[7:0];
wire b1 = |a_i[15:8];
wire b2 = |a_i[23:16];
wire b3 = |a_i[31:24];

wire m3 = 1'b1;
wire m2 = ~b3;
wire m1 = ~(b3 | b2);
wire m0 = ~(b3 | b2 | b1);
wire hit = b3 | b2 | b1 | b0;

// per-byte local encode (3 bits)
wire c2_0 = |a_i[7:4];
wire c2_1 = |a_i[15:12];
wire c2_2 = |a_i[23:20];
wire c2_3 = |a_i[31:28];

wire c1_0 = a_i[7] | a_i[6] | (~c2_0 & (a_i[3] | a_i[2]));
wire c1_1 = a_i[15] | a_i[14] | (~c2_1 & (a_i[11] | a_i[10]));
wire c1_2 = a_i[23] | a_i[22] | (~c2_2 & (a_i[19] | a_i[18]));
wire c1_3 = a_i[31] | a_i[30] | (~c2_3 & (a_i[27] | a_i[26]));

wire c0_0 = a_i[7] | (~a_i[6] & a_i[5]) | (~(a_i[6]|a_i[5]|a_i[4]) & a_i[3]) | (~(a_i[6]|a_i[5]|a_i[4]|a_i[3]|a_i[2]) & a_i[1]);
wire c0_1 = a_i[15] | (~a_i[14] & a_i[13]) | (~(a_i[14]|a_i[13]|a_i[12]) & a_i[11]) | (~(a_i[14]|a_i[13]|a_i[12]|a_i[11]|a_i[10]) & a_i[9]);
wire c0_2 = a_i[23] | (~a_i[22] & a_i[21]) | (~(a_i[22]|a_i[21]|a_i[20]) & a_i[19]) | (~(a_i[22]|a_i[21]|a_i[20]|a_i[19]|a_i[18]) & a_i[17]);
wire c0_3 = a_i[31] | (~a_i[30] & a_i[29]) | (~(a_i[30]|a_i[29]|a_i[28]) & a_i[27]) | (~(a_i[30]|a_i[29]|a_i[28]|a_i[27]|a_i[26]) & a_i[25]);

wire idx4 = b3 | b2;
wire idx3 = b3 | (m1 & b1);
wire idx2 = c2_3 | (m2 & c2_2) | (m1 & c2_1) | (m0 & c2_0);
wire idx1 = c1_3 | (m2 & c1_2) | (m1 & c1_1) | (m0 & c1_0);
wire idx0 = c0_3 | (m2 & c0_2) | (m1 & c0_1) | (m0 & c0_0);

wire [5:0] chosen = {hit, idx4, idx3, idx2, idx1, idx0};

wire sc = rst_n & valid_i;
wire sh = rst_n & ~valid_i;

always @(posedge clk) begin
    valid_o <= sc;
    y_o <= (chosen & {6{sc}}) | (y_o & {6{sh}});
end
endmodule

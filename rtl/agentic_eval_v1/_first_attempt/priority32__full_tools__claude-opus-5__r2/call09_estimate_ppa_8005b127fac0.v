module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// nibble level
wire q0 = |a_i[3:0];
wire q1 = |a_i[7:4];
wire q2 = |a_i[11:8];
wire q3 = |a_i[15:12];
wire q4 = |a_i[19:16];
wire q5 = |a_i[23:20];
wire q6 = |a_i[27:24];
wire q7 = |a_i[31:28];

wire e1_0 = a_i[3]  | a_i[2];
wire e1_1 = a_i[7]  | a_i[6];
wire e1_2 = a_i[11] | a_i[10];
wire e1_3 = a_i[15] | a_i[14];
wire e1_4 = a_i[19] | a_i[18];
wire e1_5 = a_i[23] | a_i[22];
wire e1_6 = a_i[27] | a_i[26];
wire e1_7 = a_i[31] | a_i[30];

wire e0_0 = a_i[3]  | (~a_i[2]  & a_i[1]);
wire e0_1 = a_i[7]  | (~a_i[6]  & a_i[5]);
wire e0_2 = a_i[11] | (~a_i[10] & a_i[9]);
wire e0_3 = a_i[15] | (~a_i[14] & a_i[13]);
wire e0_4 = a_i[19] | (~a_i[18] & a_i[17]);
wire e0_5 = a_i[23] | (~a_i[22] & a_i[21]);
wire e0_6 = a_i[27] | (~a_i[26] & a_i[25]);
wire e0_7 = a_i[31] | (~a_i[30] & a_i[29]);

// byte-local encodes (depth ~3)
wire E2_0 = q1;
wire E2_1 = q3;
wire E2_2 = q5;
wire E2_3 = q7;
wire E1_0 = e1_1 | (~q1 & e1_0);
wire E1_1 = e1_3 | (~q3 & e1_2);
wire E1_2 = e1_5 | (~q5 & e1_4);
wire E1_3 = e1_7 | (~q7 & e1_6);
wire E0_0 = e0_1 | (~q1 & e0_0);
wire E0_1 = e0_3 | (~q3 & e0_2);
wire E0_2 = e0_5 | (~q5 & e0_4);
wire E0_3 = e0_7 | (~q7 & e0_6);

wire b0 = q1 | q0;
wire b1 = q3 | q2;
wire b2 = q5 | q4;
wire b3 = q7 | q6;

wire m2 = ~b3;
wire m1 = ~(b3 | b2);
wire m0 = ~(b3 | b2 | b1);
wire hit = b3 | b2 | b1 | b0;

wire idx4 = b3 | b2;
wire idx3 = b3 | (m1 & b1);
wire idx2 = E2_3 | (m2 & E2_2) | (m1 & E2_1) | (m0 & E2_0);
wire idx1 = E1_3 | (m2 & E1_2) | (m1 & E1_1) | (m0 & E1_0);
wire idx0 = E0_3 | (m2 & E0_2) | (m1 & E0_1) | (m0 & E0_0);

wire [5:0] chosen = {hit, idx4, idx3, idx2, idx1, idx0};

wire sc = rst_n & valid_i;
wire sh = rst_n & ~valid_i;

always @(posedge clk) begin
    valid_o <= sc;
    y_o <= (chosen & {6{sc}}) | (y_o & {6{sh}});
end
endmodule

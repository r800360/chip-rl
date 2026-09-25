module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// pair level signals (fanout of each a_i bit kept low)
wire ph0 = a_i[3]  | a_i[2];
wire ph1 = a_i[7]  | a_i[6];
wire ph2 = a_i[11] | a_i[10];
wire ph3 = a_i[15] | a_i[14];
wire ph4 = a_i[19] | a_i[18];
wire ph5 = a_i[23] | a_i[22];
wire ph6 = a_i[27] | a_i[26];
wire ph7 = a_i[31] | a_i[30];
wire pl0 = a_i[1]  | a_i[0];
wire pl1 = a_i[5]  | a_i[4];
wire pl2 = a_i[9]  | a_i[8];
wire pl3 = a_i[13] | a_i[12];
wire pl4 = a_i[17] | a_i[16];
wire pl5 = a_i[21] | a_i[20];
wire pl6 = a_i[25] | a_i[24];
wire pl7 = a_i[29] | a_i[28];

wire q0 = ph0 | pl0;
wire q1 = ph1 | pl1;
wire q2 = ph2 | pl2;
wire q3 = ph3 | pl3;
wire q4 = ph4 | pl4;
wire q5 = ph5 | pl5;
wire q6 = ph6 | pl6;
wire q7 = ph7 | pl7;

wire e0_0 = a_i[3]  | (~a_i[2]  & a_i[1]);
wire e0_1 = a_i[7]  | (~a_i[6]  & a_i[5]);
wire e0_2 = a_i[11] | (~a_i[10] & a_i[9]);
wire e0_3 = a_i[15] | (~a_i[14] & a_i[13]);
wire e0_4 = a_i[19] | (~a_i[18] & a_i[17]);
wire e0_5 = a_i[23] | (~a_i[22] & a_i[21]);
wire e0_6 = a_i[27] | (~a_i[26] & a_i[25]);
wire e0_7 = a_i[31] | (~a_i[30] & a_i[29]);

wire g8_3 = q7 | q6;
wire g8_2 = q5 | q4;
wire g8_1 = q3 | q2;
wire g8_0 = q1 | q0;
wire g16_1 = g8_3 | g8_2;
wire g16_0 = g8_1 | g8_0;
wire hit   = g16_1 | g16_0;

wire n6 = ~q7;
wire n5 = ~g8_3;
wire n4 = ~(g8_3 | q5);
wire n3 = ~g16_1;
wire n2 = ~(g16_1 | q3);
wire n1 = ~(g16_1 | g8_1);
wire n0 = ~(g16_1 | g8_1 | q1);

wire idx4 = g16_1;
wire idx3 = g8_3 | (n3 & g8_1);
wire idx2 = q7 | (n5 & q5) | (n3 & q3) | (n1 & q1);
wire idx1 = ph7 | (n6 & ph6) | (n5 & ph5) | (n4 & ph4) |
            (n3 & ph3) | (n2 & ph2) | (n1 & ph1) | (n0 & ph0);
wire idx0 = e0_7 | (n6 & e0_6) | (n5 & e0_5) | (n4 & e0_4) |
            (n3 & e0_3) | (n2 & e0_2) | (n1 & e0_1) | (n0 & e0_0);

wire [5:0] chosen = {hit, idx4, idx3, idx2, idx1, idx0};

wire sc = rst_n & valid_i;
wire sh = rst_n & ~valid_i;

always @(posedge clk) begin
    valid_o <= sc;
    y_o <= (chosen & {6{sc}}) | (y_o & {6{sh}});
end
endmodule

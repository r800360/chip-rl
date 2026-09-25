module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

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

wire g8_3 = q7 | q6;
wire g8_2 = q5 | q4;
wire g8_1 = q3 | q2;
wire g8_0 = q1 | q0;
wire g16_1 = g8_3 | g8_2;
wire g16_0 = g8_1 | g8_0;
wire hit   = g16_1 | g16_0;

wire n7 = 1'b1;
wire n6 = ~q7;
wire n5 = ~g8_3;
wire n4 = ~(g8_3 | q5);
wire n3 = ~g16_1;
wire n2 = ~(g16_1 | q3);
wire n1 = ~(g16_1 | g8_1);
wire n0 = ~(g16_1 | g8_1 | q1);

wire w7 = q7;
wire w6 = n6 & q6;
wire w5 = n5 & q5;
wire w4 = n4 & q4;
wire w3 = n3 & q3;
wire w2 = n2 & q2;
wire w1 = n1 & q1;
wire w0 = n0 & q0;

wire idx4 = g16_1;
wire idx3 = g8_3 | (n3 & g8_1);
wire idx2 = w7 | w5 | w3 | w1;
wire idx1 = (n7 & e1_7) | (n6 & e1_6) | (n5 & e1_5) | (n4 & e1_4) |
            (n3 & e1_3) | (n2 & e1_2) | (n1 & e1_1) | (n0 & e1_0);
wire idx0 = (n7 & e0_7) | (n6 & e0_6) | (n5 & e0_5) | (n4 & e0_4) |
            (n3 & e0_3) | (n2 & e0_2) | (n1 & e0_1) | (n0 & e0_0);

wire [5:0] chosen = {hit, idx4, idx3, idx2, idx1, idx0};

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

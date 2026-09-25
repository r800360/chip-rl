module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// nibble level, inverted-polarity friendly
wire [7:0] np, n1, n0;
assign np[0] = ~(|a_i[3:0]);   assign n1[0] = a_i[3]  | a_i[2];   assign n0[0] = a_i[3]  | (~a_i[2]  & a_i[1]);
assign np[1] = ~(|a_i[7:4]);   assign n1[1] = a_i[7]  | a_i[6];   assign n0[1] = a_i[7]  | (~a_i[6]  & a_i[5]);
assign np[2] = ~(|a_i[11:8]);  assign n1[2] = a_i[11] | a_i[10];  assign n0[2] = a_i[11] | (~a_i[10] & a_i[9]);
assign np[3] = ~(|a_i[15:12]); assign n1[3] = a_i[15] | a_i[14];  assign n0[3] = a_i[15] | (~a_i[14] & a_i[13]);
assign np[4] = ~(|a_i[19:16]); assign n1[4] = a_i[19] | a_i[18];  assign n0[4] = a_i[19] | (~a_i[18] & a_i[17]);
assign np[5] = ~(|a_i[23:20]); assign n1[5] = a_i[23] | a_i[22];  assign n0[5] = a_i[23] | (~a_i[22] & a_i[21]);
assign np[6] = ~(|a_i[27:24]); assign n1[6] = a_i[27] | a_i[26];  assign n0[6] = a_i[27] | (~a_i[26] & a_i[25]);
assign np[7] = ~(|a_i[31:28]); assign n1[7] = a_i[31] | a_i[30];  assign n0[7] = a_i[31] | (~a_i[30] & a_i[29]);

// level 2 : inverted byte data (AOI22 style), selects from np
wire nb0_0 = ~((~np[1] & n0[1]) | (np[1] & n0[0]));
wire nb0_1 = ~((~np[3] & n0[3]) | (np[3] & n0[2]));
wire nb0_2 = ~((~np[5] & n0[5]) | (np[5] & n0[4]));
wire nb0_3 = ~((~np[7] & n0[7]) | (np[7] & n0[6]));
wire nb1_0 = ~((~np[1] & n1[1]) | (np[1] & n1[0]));
wire nb1_1 = ~((~np[3] & n1[3]) | (np[3] & n1[2]));
wire nb1_2 = ~((~np[5] & n1[5]) | (np[5] & n1[4]));
wire nb1_3 = ~((~np[7] & n1[7]) | (np[7] & n1[6]));
wire nb2_0 = ~(~np[1]);
wire nb2_1 = ~(~np[3]);
wire nb2_2 = ~(~np[5]);
wire nb2_3 = ~(~np[7]);

wire [3:0] bp;
assign bp[0] = np[1] & np[0];
assign bp[1] = np[3] & np[2];
assign bp[2] = np[5] & np[4];
assign bp[3] = np[7] & np[6];
wire hp1 = np[7] & np[6] & np[5] & np[4];
wire hp0 = np[3] & np[2] & np[1] & np[0];

// level 3 : non-inverted half data (OAI22 style from inverted inputs)
wire h0_0 = (bp[1] | nb0_1) & (~bp[1] | nb0_0) ? 1'b0 : 1'b1;
wire h0_1 = (bp[3] | nb0_3) & (~bp[3] | nb0_2) ? 1'b0 : 1'b1;
wire h1_0 = (bp[1] | nb1_1) & (~bp[1] | nb1_0) ? 1'b0 : 1'b1;
wire h1_1 = (bp[3] | nb1_3) & (~bp[3] | nb1_2) ? 1'b0 : 1'b1;
wire h2_0 = (bp[1] | nb2_1) & (~bp[1] | nb2_0) ? 1'b0 : 1'b1;
wire h2_1 = (bp[3] | nb2_3) & (~bp[3] | nb2_2) ? 1'b0 : 1'b1;
wire h3_0 = ~bp[1];
wire h3_1 = ~bp[3];

wire en  = valid_i & rst_n;
wire hen = ~valid_i & rst_n;
wire s1  = en & ~hp1;
wire s0  = en & hp1;
wire s5  = en & ~hp0;

wire [5:0] d;
assign d[0] = (s1 & h0_1) | (s0 & h0_0) | (hen & y_o[0]);
assign d[1] = (s1 & h1_1) | (s0 & h1_0) | (hen & y_o[1]);
assign d[2] = (s1 & h2_1) | (s0 & h2_0) | (hen & y_o[2]);
assign d[3] = (s1 & h3_1) | (s0 & h3_0) | (hen & y_o[3]);
assign d[4] = s1 | (hen & y_o[4]);
assign d[5] = s1 | s5 | (hen & y_o[5]);

always @(posedge clk) begin
    valid_o <= en;
    y_o <= d;
end
endmodule
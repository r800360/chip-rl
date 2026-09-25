module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// level-1 signals: every a_i bit drives at most two gates
wire [7:0] n1, mm, n0;
assign n1[0] = a_i[3]  | a_i[2];   assign mm[0] = a_i[1]  | a_i[0];   assign n0[0] = a_i[3]  | (~a_i[2]  & a_i[1]);
assign n1[1] = a_i[7]  | a_i[6];   assign mm[1] = a_i[5]  | a_i[4];   assign n0[1] = a_i[7]  | (~a_i[6]  & a_i[5]);
assign n1[2] = a_i[11] | a_i[10];  assign mm[2] = a_i[9]  | a_i[8];   assign n0[2] = a_i[11] | (~a_i[10] & a_i[9]);
assign n1[3] = a_i[15] | a_i[14];  assign mm[3] = a_i[13] | a_i[12];  assign n0[3] = a_i[15] | (~a_i[14] & a_i[13]);
assign n1[4] = a_i[19] | a_i[18];  assign mm[4] = a_i[17] | a_i[16];  assign n0[4] = a_i[19] | (~a_i[18] & a_i[17]);
assign n1[5] = a_i[23] | a_i[22];  assign mm[5] = a_i[21] | a_i[20];  assign n0[5] = a_i[23] | (~a_i[22] & a_i[21]);
assign n1[6] = a_i[27] | a_i[26];  assign mm[6] = a_i[25] | a_i[24];  assign n0[6] = a_i[27] | (~a_i[26] & a_i[25]);
assign n1[7] = a_i[31] | a_i[30];  assign mm[7] = a_i[29] | a_i[28];  assign n0[7] = a_i[31] | (~a_i[30] & a_i[29]);

wire [7:0] nh = n1 | mm;
wire [3:0] bh;
assign bh[0] = n1[1] | mm[1] | n1[0] | mm[0];
assign bh[1] = n1[3] | mm[3] | n1[2] | mm[2];
assign bh[2] = n1[5] | mm[5] | n1[4] | mm[4];
assign bh[3] = n1[7] | mm[7] | n1[6] | mm[6];
wire hh1 = n1[7]|mm[7]|n1[6]|mm[6]|n1[5]|mm[5]|n1[4]|mm[4];
wire hh0 = n1[3]|mm[3]|n1[2]|mm[2]|n1[1]|mm[1]|n1[0]|mm[0];
wire hit = hh1 | hh0;

wire [3:0] b1, b0;
assign b1[0] = nh[1] ? n1[1] : n1[0];
assign b0[0] = nh[1] ? n0[1] : n0[0];
assign b1[1] = nh[3] ? n1[3] : n1[2];
assign b0[1] = nh[3] ? n0[3] : n0[2];
assign b1[2] = nh[5] ? n1[5] : n1[4];
assign b0[2] = nh[5] ? n0[5] : n0[4];
assign b1[3] = nh[7] ? n1[7] : n1[6];
assign b0[3] = nh[7] ? n0[7] : n0[6];

wire h1_1 = bh[3] ? b1[3] : b1[2];
wire h1_0 = bh[1] ? b1[1] : b1[0];
wire h0_1 = bh[3] ? b0[3] : b0[2];
wire h0_0 = bh[1] ? b0[1] : b0[0];
wire h2_1 = bh[3] ? nh[7] : nh[5];
wire h2_0 = bh[1] ? nh[3] : nh[1];

wire w4 = hh1;
wire w3 = hh1 ? bh[3] : bh[1];
wire w2 = hh1 ? h2_1 : h2_0;
wire w1 = hh1 ? h1_1 : h1_0;
wire w0 = hh1 ? h0_1 : h0_0;

wire [5:0] chosen_0 = {hit, w4, w3, w2, w1, w0};
wire en  = valid_i & rst_n;
wire hen = ~valid_i & rst_n;
always @(posedge clk) begin
    valid_o <= en;
    y_o <= (chosen_0 & {6{en}}) | (y_o & {6{hen}});
end
endmodule
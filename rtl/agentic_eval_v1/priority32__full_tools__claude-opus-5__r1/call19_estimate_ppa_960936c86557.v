module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// level 1: exactly three loads per a_i bit
wire [7:0] nh, n1, n0;
assign nh[0] = |a_i[3:0];   assign n1[0] = a_i[3]  | a_i[2];   assign n0[0] = a_i[3]  | (~a_i[2]  & a_i[1]);
assign nh[1] = |a_i[7:4];   assign n1[1] = a_i[7]  | a_i[6];   assign n0[1] = a_i[7]  | (~a_i[6]  & a_i[5]);
assign nh[2] = |a_i[11:8];  assign n1[2] = a_i[11] | a_i[10];  assign n0[2] = a_i[11] | (~a_i[10] & a_i[9]);
assign nh[3] = |a_i[15:12]; assign n1[3] = a_i[15] | a_i[14];  assign n0[3] = a_i[15] | (~a_i[14] & a_i[13]);
assign nh[4] = |a_i[19:16]; assign n1[4] = a_i[19] | a_i[18];  assign n0[4] = a_i[19] | (~a_i[18] & a_i[17]);
assign nh[5] = |a_i[23:20]; assign n1[5] = a_i[23] | a_i[22];  assign n0[5] = a_i[23] | (~a_i[22] & a_i[21]);
assign nh[6] = |a_i[27:24]; assign n1[6] = a_i[27] | a_i[26];  assign n0[6] = a_i[27] | (~a_i[26] & a_i[25]);
assign nh[7] = |a_i[31:28]; assign n1[7] = a_i[31] | a_i[30];  assign n0[7] = a_i[31] | (~a_i[30] & a_i[29]);

// level 2: selects derived from nh only
wire [3:0] bh;
assign bh[0] = nh[1] | nh[0];
assign bh[1] = nh[3] | nh[2];
assign bh[2] = nh[5] | nh[4];
assign bh[3] = nh[7] | nh[6];
wire hh1 = nh[7] | nh[6] | nh[5] | nh[4];
wire hh0 = nh[3] | nh[2] | nh[1] | nh[0];

// level 2: data muxes
wire b0_0 = (nh[1] & n0[1]) | (~nh[1] & n0[0]);
wire b0_1 = (nh[3] & n0[3]) | (~nh[3] & n0[2]);
wire b0_2 = (nh[5] & n0[5]) | (~nh[5] & n0[4]);
wire b0_3 = (nh[7] & n0[7]) | (~nh[7] & n0[6]);
wire b1_0 = (nh[1] & n1[1]) | (~nh[1] & n1[0]);
wire b1_1 = (nh[3] & n1[3]) | (~nh[3] & n1[2]);
wire b1_2 = (nh[5] & n1[5]) | (~nh[5] & n1[4]);
wire b1_3 = (nh[7] & n1[7]) | (~nh[7] & n1[6]);

// level 3: data muxes
wire h0_0 = (bh[1] & b0_1) | (~bh[1] & b0_0);
wire h0_1 = (bh[3] & b0_3) | (~bh[3] & b0_2);
wire h1_0 = (bh[1] & b1_1) | (~bh[1] & b1_0);
wire h1_1 = (bh[3] & b1_3) | (~bh[3] & b1_2);
wire h2_0 = (bh[1] & nh[3]) | (~bh[1] & nh[1]);
wire h2_1 = (bh[3] & nh[7]) | (~bh[3] & nh[5]);

// level 3: controls
wire en  = valid_i & rst_n;
wire hen = ~valid_i & rst_n;
wire s1  = en & hh1;
wire s0  = en & ~hh1;
wire s5  = en & hh0;

// level 4: final select merged with enable / hold
wire [5:0] d;
assign d[0] = (s1 & h0_1) | (s0 & h0_0) | (hen & y_o[0]);
assign d[1] = (s1 & h1_1) | (s0 & h1_0) | (hen & y_o[1]);
assign d[2] = (s1 & h2_1) | (s0 & h2_0) | (hen & y_o[2]);
assign d[3] = (s1 & bh[3]) | (s0 & bh[1]) | (hen & y_o[3]);
assign d[4] = s1 | (hen & y_o[4]);
assign d[5] = s1 | s5 | (hen & y_o[5]);

always @(posedge clk) begin
    valid_o <= en;
    y_o <= d;
end
endmodule
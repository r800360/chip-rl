module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [3:0] bh;
assign bh[3] = |a_i[31:24];
assign bh[2] = |a_i[23:16];
assign bh[1] = |a_i[15:8];
assign bh[0] = |a_i[7:0];
wire hh1 = bh[3] | bh[2];
wire hh0 = bh[1] | bh[0];
wire [2:0] e3 = a_i[31] ? 3'd7 : a_i[30] ? 3'd6 : a_i[29] ? 3'd5 : a_i[28] ? 3'd4 : a_i[27] ? 3'd3 : a_i[26] ? 3'd2 : a_i[25] ? 3'd1 : 3'd0;
wire [2:0] e2 = a_i[23] ? 3'd7 : a_i[22] ? 3'd6 : a_i[21] ? 3'd5 : a_i[20] ? 3'd4 : a_i[19] ? 3'd3 : a_i[18] ? 3'd2 : a_i[17] ? 3'd1 : 3'd0;
wire [2:0] e1 = a_i[15] ? 3'd7 : a_i[14] ? 3'd6 : a_i[13] ? 3'd5 : a_i[12] ? 3'd4 : a_i[11] ? 3'd3 : a_i[10] ? 3'd2 : a_i[9]  ? 3'd1 : 3'd0;
wire [2:0] e0 = a_i[7]  ? 3'd7 : a_i[6]  ? 3'd6 : a_i[5]  ? 3'd5 : a_i[4]  ? 3'd4 : a_i[3]  ? 3'd3 : a_i[2]  ? 3'd2 : a_i[1]  ? 3'd1 : 3'd0;
wire [2:0] uH = bh[3] ? e3 : e2;
wire [2:0] uL = bh[1] ? e1 : e0;
wire en  = valid_i & rst_n;
wire hen = ~valid_i & rst_n;
wire s1  = en & hh1;
wire s0  = en & ~hh1;
wire s5  = en & hh0;
wire [5:0] d;
assign d[0] = (s1 & uH[0]) | (s0 & uL[0]) | (hen & y_o[0]);
assign d[1] = (s1 & uH[1]) | (s0 & uL[1]) | (hen & y_o[1]);
assign d[2] = (s1 & uH[2]) | (s0 & uL[2]) | (hen & y_o[2]);
assign d[3] = (s1 & bh[3]) | (s0 & bh[1]) | (hen & y_o[3]);
assign d[4] = s1 | (hen & y_o[4]);
assign d[5] = s1 | s5 | (hen & y_o[5]);
always @(posedge clk) begin
    valid_o <= en;
    y_o <= d;
end
endmodule
module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire hh1 = |a_i[31:16];
wire hh0 = |a_i[15:0];
wire [3:0] iH = a_i[31] ? 4'd15 : a_i[30] ? 4'd14 : a_i[29] ? 4'd13 : a_i[28] ? 4'd12 : a_i[27] ? 4'd11 : a_i[26] ? 4'd10 : a_i[25] ? 4'd9 : a_i[24] ? 4'd8 : a_i[23] ? 4'd7 : a_i[22] ? 4'd6 : a_i[21] ? 4'd5 : a_i[20] ? 4'd4 : a_i[19] ? 4'd3 : a_i[18] ? 4'd2 : a_i[17] ? 4'd1 : 4'd0;
wire [3:0] iL = a_i[15] ? 4'd15 : a_i[14] ? 4'd14 : a_i[13] ? 4'd13 : a_i[12] ? 4'd12 : a_i[11] ? 4'd11 : a_i[10] ? 4'd10 : a_i[9] ? 4'd9 : a_i[8] ? 4'd8 : a_i[7] ? 4'd7 : a_i[6] ? 4'd6 : a_i[5] ? 4'd5 : a_i[4] ? 4'd4 : a_i[3] ? 4'd3 : a_i[2] ? 4'd2 : a_i[1] ? 4'd1 : 4'd0;
wire en  = valid_i & rst_n;
wire hen = ~valid_i & rst_n;
wire s1  = en & hh1;
wire s0  = en & ~hh1;
wire s5  = en & hh0;
wire [5:0] d;
assign d[0] = (s1 & iH[0]) | (s0 & iL[0]) | (hen & y_o[0]);
assign d[1] = (s1 & iH[1]) | (s0 & iL[1]) | (hen & y_o[1]);
assign d[2] = (s1 & iH[2]) | (s0 & iL[2]) | (hen & y_o[2]);
assign d[3] = (s1 & iH[3]) | (s0 & iL[3]) | (hen & y_o[3]);
assign d[4] = s1 | (hen & y_o[4]);
assign d[5] = s1 | s5 | (hen & y_o[5]);
always @(posedge clk) begin
    valid_o <= en;
    y_o <= d;
end
endmodule
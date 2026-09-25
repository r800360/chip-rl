module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [7:0] nh, n1, n0;
assign nh[0] = |a_i[3:0];   assign n1[0] = |a_i[3:2];   assign n0[0] = a_i[3] | (a_i[1] & ~a_i[2]);
assign nh[1] = |a_i[7:4];   assign n1[1] = |a_i[7:6];   assign n0[1] = a_i[7] | (a_i[5] & ~a_i[6]);
assign nh[2] = |a_i[11:8];  assign n1[2] = |a_i[11:10]; assign n0[2] = a_i[11] | (a_i[9] & ~a_i[10]);
assign nh[3] = |a_i[15:12]; assign n1[3] = |a_i[15:14]; assign n0[3] = a_i[15] | (a_i[13] & ~a_i[14]);
assign nh[4] = |a_i[19:16]; assign n1[4] = |a_i[19:18]; assign n0[4] = a_i[19] | (a_i[17] & ~a_i[18]);
assign nh[5] = |a_i[23:20]; assign n1[5] = |a_i[23:22]; assign n0[5] = a_i[23] | (a_i[21] & ~a_i[22]);
assign nh[6] = |a_i[27:24]; assign n1[6] = |a_i[27:26]; assign n0[6] = a_i[27] | (a_i[25] & ~a_i[26]);
assign nh[7] = |a_i[31:28]; assign n1[7] = |a_i[31:30]; assign n0[7] = a_i[31] | (a_i[29] & ~a_i[30]);

wire [3:0] bh, b1, b0;
assign bh[0] = nh[1] | nh[0];
assign b1[0] = nh[1] ? n1[1] : n1[0];
assign b0[0] = nh[1] ? n0[1] : n0[0];
assign bh[1] = nh[3] | nh[2];
assign b1[1] = nh[3] ? n1[3] : n1[2];
assign b0[1] = nh[3] ? n0[3] : n0[2];
assign bh[2] = nh[5] | nh[4];
assign b1[2] = nh[5] ? n1[5] : n1[4];
assign b0[2] = nh[5] ? n0[5] : n0[4];
assign bh[3] = nh[7] | nh[6];
assign b1[3] = nh[7] ? n1[7] : n1[6];
assign b0[3] = nh[7] ? n0[7] : n0[6];

wire hh1 = bh[3] | bh[2];
wire hh0 = bh[1] | bh[0];
wire h2a = nh[7] | nh[5];
wire h2b = nh[3] | nh[1];
wire [1:0] h1v, h0v, h2v;
assign h2v[1] = bh[3] ? nh[7] : nh[5];
assign h2v[0] = bh[1] ? nh[3] : nh[1];
assign h1v[1] = bh[3] ? b1[3] : b1[2];
assign h1v[0] = bh[1] ? b1[1] : b1[0];
assign h0v[1] = bh[3] ? b0[3] : b0[2];
assign h0v[0] = bh[1] ? b0[1] : b0[0];

wire hit = hh1 | hh0;
wire w4 = hh1;
wire w3 = hh1 ? bh[3] : bh[1];
wire w2 = hh1 ? h2v[1] : h2v[0];
wire w1 = hh1 ? h1v[1] : h1v[0];
wire w0 = hh1 ? h0v[1] : h0v[0];

wire [5:0] chosen_0 = {hit, w4, w3, w2, w1, w0};
wire en = valid_i & rst_n;

always @(posedge clk) begin
    valid_o <= en;
    y_o <= en ? chosen_0 : (y_o & {6{rst_n}});
end
endmodule
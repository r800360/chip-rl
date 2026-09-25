module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire o16 = |a_i[31:16];
wire o24 = |a_i[31:24];
wire o28 = |a_i[31:28];
wire o20 = |a_i[31:20];
wire o12 = |a_i[31:12];
wire o8  = |a_i[31:8];
wire o4  = |a_i[31:4];
wire idx4 = o16;
wire idx3 = o24 | (~o16 & |a_i[15:8]);
wire idx2 = o28 | (~o24 & |a_i[23:20]) | (~o16 & |a_i[15:12]) | (~o12 & |a_i[7:4]);
wire idx1 = (|a_i[31:30]) | (~o28 & |a_i[27:26]) | (~o24 & |a_i[23:22]) |
            (~o20 & |a_i[19:18]) | (~o16 & |a_i[15:14]) | (~o12 & |a_i[11:10]) |
            (~o8  & |a_i[7:6])   | (~o4  & |a_i[3:2]);
wire idx0 = a_i[31] | (~a_i[31] & a_i[29]) | (~|a_i[31:29] & a_i[27]) | (~|a_i[31:27] & a_i[25]) |
            (~|a_i[31:25] & a_i[23]) | (~|a_i[31:23] & a_i[21]) | (~|a_i[31:21] & a_i[19]) |
            (~|a_i[31:19] & a_i[17]) | (~|a_i[31:17] & a_i[15]) | (~|a_i[31:15] & a_i[13]) |
            (~|a_i[31:13] & a_i[11]) | (~|a_i[31:11] & a_i[9]) | (~|a_i[31:9] & a_i[7]) |
            (~|a_i[31:7] & a_i[5]) | (~|a_i[31:5] & a_i[3]) | (~|a_i[31:3] & a_i[1]);
wire hit = o16 | |a_i[15:0];
wire [5:0] chosen_0 = {hit, idx4, idx3, idx2, idx1, idx0};
wire en = valid_i & rst_n;
always @(posedge clk) begin
    valid_o <= en;
    y_o <= en ? chosen_0 : (y_o & {6{rst_n}});
end
endmodule
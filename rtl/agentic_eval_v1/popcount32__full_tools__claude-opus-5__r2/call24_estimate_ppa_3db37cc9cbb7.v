module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
function [1:0] fa3; input x; input y; input z;
    fa3 = {(x & y) | (x & z) | (y & z), x ^ y ^ z};
endfunction
function [1:0] ha2; input x; input y;
    ha2 = {x & y, x ^ y};
endfunction

reg [12:0] pr;
reg [5:0] yh;

wire [3:0] S = pr[3:0];
wire [3:0] C = pr[7:4];
wire [3:0] D = pr[11:8];
wire AO = pr[12];

wire [1:0] w1 = ha2(S[0], D[0]);
wire [1:0] w2 = fa3(S[1], D[1], C[0]);
wire [1:0] w4 = fa3(S[2], D[2], C[1]);
wire [1:0] w8 = fa3(S[3], D[3], C[2]);

wire [3:0] P = {C[3], w8[0], w4[0], w2[0]};
wire [3:0] Q = {w8[1], w4[1], w2[1], w1[1]};
wire [3:0] gg = P & Q;
wire [3:0] pp = P ^ Q;
wire cy1 = gg[0];
wire cy2 = gg[1] | (pp[1] & gg[0]);
wire cy3 = gg[2] | (pp[2] & gg[1]) | (pp[2] & pp[1] & gg[0]);
wire [5:0] ycomb = {AO, pp[3] ^ cy3, pp[2] ^ cy2, pp[1] ^ cy1, pp[0], w1[0]};

always @(posedge clk) begin
    pr <= a_i[12:0];
    if (!rst_n) begin
        valid_o <= 1'b0;
        yh <= 6'd0;
    end else begin
        valid_o <= valid_i;
        yh <= y_o;
    end
end

always @* y_o = valid_o ? ycomb : yh;
endmodule
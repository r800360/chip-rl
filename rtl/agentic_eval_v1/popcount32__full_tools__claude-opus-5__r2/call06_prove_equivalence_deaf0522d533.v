module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

reg [31:0] ar;

function [1:0] fa3;
    input x; input y; input z;
    begin
        fa3 = {(x & y) | (x & z) | (y & z), x ^ y ^ z};
    end
endfunction

function [1:0] ha2;
    input x; input y;
    begin
        ha2 = {x & y, x ^ y};
    end
endfunction

wire [1:0] g0 = fa3(ar[0],  ar[1],  ar[2]);
wire [1:0] g1 = fa3(ar[3],  ar[4],  ar[5]);
wire [1:0] g2 = fa3(ar[6],  ar[7],  ar[8]);
wire [1:0] g3 = fa3(ar[9],  ar[10], ar[11]);
wire [1:0] g4 = fa3(ar[12], ar[13], ar[14]);
wire [1:0] g5 = fa3(ar[15], ar[16], ar[17]);
wire [1:0] g6 = fa3(ar[18], ar[19], ar[20]);
wire [1:0] g7 = fa3(ar[21], ar[22], ar[23]);
wire [1:0] g8 = fa3(ar[24], ar[25], ar[26]);
wire [1:0] g9 = fa3(ar[27], ar[28], ar[29]);
wire [1:0] h0 = fa3(g0[0], g1[0], g2[0]);
wire [1:0] h1 = fa3(g3[0], g4[0], g5[0]);
wire [1:0] h2 = fa3(g6[0], g7[0], g8[0]);
wire [1:0] h3 = fa3(g9[0], ar[30], ar[31]);
wire [1:0] i0 = fa3(h0[0], h1[0], h2[0]);
wire [1:0] j0 = ha2(i0[0], h3[0]);
wire [1:0] k0 = fa3(g0[1], g1[1], g2[1]);
wire [1:0] k1 = fa3(g3[1], g4[1], g5[1]);
wire [1:0] k2 = fa3(g6[1], g7[1], g8[1]);
wire [1:0] k3 = fa3(g9[1], h0[1], h1[1]);
wire [1:0] k4 = fa3(h2[1], h3[1], i0[1]);
wire [1:0] m0 = fa3(k0[0], k1[0], k2[0]);
wire [1:0] m1 = fa3(k3[0], k4[0], j0[1]);
wire [1:0] n0 = ha2(m0[0], m1[0]);
wire [1:0] p0 = fa3(k0[1], k1[1], k2[1]);
wire [1:0] p1 = fa3(k3[1], k4[1], m0[1]);
wire [1:0] q0 = fa3(p0[0], p1[0], m1[1]);
wire [1:0] r0 = ha2(q0[0], n0[1]);
wire [1:0] t0 = fa3(p0[1], p1[1], q0[1]);
wire [1:0] u0 = ha2(t0[0], r0[1]);
wire [1:0] v0 = ha2(t0[1], u0[1]);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        ar <= 32'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            ar <= a_i;
    end
end

always @* begin
    y_o = {v0[1], v0[0], u0[0], r0[0], n0[0], j0[0]};
end
endmodule
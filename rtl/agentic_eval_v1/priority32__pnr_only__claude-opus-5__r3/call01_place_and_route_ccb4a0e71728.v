module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// ---- level 1 : nibble OR, top-pair OR, odd-position flag -----------------
wire g0 = a_i[0]  | a_i[1]  | a_i[2]  | a_i[3];
wire g1 = a_i[4]  | a_i[5]  | a_i[6]  | a_i[7];
wire g2 = a_i[8]  | a_i[9]  | a_i[10] | a_i[11];
wire g3 = a_i[12] | a_i[13] | a_i[14] | a_i[15];
wire g4 = a_i[16] | a_i[17] | a_i[18] | a_i[19];
wire g5 = a_i[20] | a_i[21] | a_i[22] | a_i[23];
wire g6 = a_i[24] | a_i[25] | a_i[26] | a_i[27];
wire g7 = a_i[28] | a_i[29] | a_i[30] | a_i[31];

wire u0 = a_i[3]  | a_i[2];
wire u1 = a_i[7]  | a_i[6];
wire u2 = a_i[11] | a_i[10];
wire u3 = a_i[15] | a_i[14];
wire u4 = a_i[19] | a_i[18];
wire u5 = a_i[23] | a_i[22];
wire u6 = a_i[27] | a_i[26];
wire u7 = a_i[31] | a_i[30];

wire v0 = a_i[3]  | (~a_i[2]  & a_i[1]);
wire v1 = a_i[7]  | (~a_i[6]  & a_i[5]);
wire v2 = a_i[11] | (~a_i[10] & a_i[9]);
wire v3 = a_i[15] | (~a_i[14] & a_i[13]);
wire v4 = a_i[19] | (~a_i[18] & a_i[17]);
wire v5 = a_i[23] | (~a_i[22] & a_i[21]);
wire v6 = a_i[27] | (~a_i[26] & a_i[25]);
wire v7 = a_i[31] | (~a_i[30] & a_i[29]);

// ---- level 2 : upper-half empty flag -------------------------------------
wire nt3 = ~(g7 | g6 | g5 | g4);          // no set bit in a_i[31:16]
wire hi4 = ~nt3;

// ---- half encoders written as flat products of level-1 literals ----------
wire hu = u7 | (u6 & ~g7) | (u5 & ~g7 & ~g6) | (u4 & ~g7 & ~g6 & ~g5);
wire lu = u3 | (u2 & ~g3) | (u1 & ~g3 & ~g2) | (u0 & ~g3 & ~g2 & ~g1);

wire hv = v7 | (v6 & ~g7) | (v5 & ~g7 & ~g6) | (v4 & ~g7 & ~g6 & ~g5);
wire lv = v3 | (v2 & ~g3) | (v1 & ~g3 & ~g2) | (v0 & ~g3 & ~g2 & ~g1);

wire hg = g7 | (g5 & ~g6 & ~g7);
wire lg = g3 | (g1 & ~g2 & ~g3);

// ---- outputs --------------------------------------------------------------
wire i4 = hi4;
wire i3 = (g7 | g6) | (nt3 & (g3 | g2));
wire i2 = hg | (nt3 & lg);
wire i1 = hu | (nt3 & lu);
wire i0 = hv | (nt3 & lv);
wire hit_0 = hi4 | (g3 | g2 | g1 | g0);

wire [5:0] chosen_0 = {hit_0, i4, i3, i2, i1, i0};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen_0;
    end
end
endmodule

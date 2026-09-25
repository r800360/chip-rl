module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// ---- level 1: 4-bit group ORs and intra-nibble helpers -------------------
wire g0 = a_i[0]  | a_i[1]  | a_i[2]  | a_i[3];
wire g1 = a_i[4]  | a_i[5]  | a_i[6]  | a_i[7];
wire g2 = a_i[8]  | a_i[9]  | a_i[10] | a_i[11];
wire g3 = a_i[12] | a_i[13] | a_i[14] | a_i[15];
wire g4 = a_i[16] | a_i[17] | a_i[18] | a_i[19];
wire g5 = a_i[20] | a_i[21] | a_i[22] | a_i[23];
wire g6 = a_i[24] | a_i[25] | a_i[26] | a_i[27];
wire g7 = a_i[28] | a_i[29] | a_i[30] | a_i[31];

// u_k : winner inside nibble k has bit1 set
wire u0 = a_i[3]  | a_i[2];
wire u1 = a_i[7]  | a_i[6];
wire u2 = a_i[11] | a_i[10];
wire u3 = a_i[15] | a_i[14];
wire u4 = a_i[19] | a_i[18];
wire u5 = a_i[23] | a_i[22];
wire u6 = a_i[27] | a_i[26];
wire u7 = a_i[31] | a_i[30];

// v_k : winner inside nibble k has bit0 set
wire v0 = a_i[3]  | (~a_i[2]  & a_i[1]);
wire v1 = a_i[7]  | (~a_i[6]  & a_i[5]);
wire v2 = a_i[11] | (~a_i[10] & a_i[9]);
wire v3 = a_i[15] | (~a_i[14] & a_i[13]);
wire v4 = a_i[19] | (~a_i[18] & a_i[17]);
wire v5 = a_i[23] | (~a_i[22] & a_i[21]);
wire v6 = a_i[27] | (~a_i[26] & a_i[25]);
wire v7 = a_i[31] | (~a_i[30] & a_i[29]);

// ---- level 2: "any higher group set" prefix (balanced) -------------------
wire t3 = (g7 | g6) | (g5 | g4);   // |a_i[31:16]
wire t5 = g7 | g6;
wire t4 = (g7 | g6) | g5;
wire t2 = t3 | g3;
wire t1 = t3 | (g3 | g2);
wire t0 = t3 | (g3 | g2 | g1);

// ---- level 3: one-hot winning group --------------------------------------
wire e7 = g7;
wire e6 = g6 & ~g7;
wire e5 = g5 & ~t5;
wire e4 = g4 & ~t4;
wire e3 = g3 & ~t3;
wire e2 = g2 & ~t2;
wire e1 = g1 & ~t1;
wire e0 = g0 & ~t0;

// ---- output bits ---------------------------------------------------------
wire hit_0 = t0 | g0;

wire i4 = t3;
wire i3 = (g7 | g6) | (~t3 & (g3 | g2));
wire i2 = (e7 | e5) | (e3 | e1);
wire i1 = ((e7 & u7) | (e6 & u6) | (e5 & u5) | (e4 & u4)) |
          ((e3 & u3) | (e2 & u2) | (e1 & u1) | (e0 & u0));
wire i0 = ((e7 & v7) | (e6 & v6) | (e5 & v5) | (e4 & v4)) |
          ((e3 & v3) | (e2 & v2) | (e1 & v1) | (e0 & v0));

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

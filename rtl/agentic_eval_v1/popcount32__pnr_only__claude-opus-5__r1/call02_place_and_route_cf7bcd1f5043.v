module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
    // ---------------- stage 1 : ten 3:2 compressors on a[0..29] ----------
    wire t0x = a_i[0] ^ a_i[1];
    wire t0s = t0x ^ a_i[2];
    wire t0c = (a_i[0] & a_i[1]) | (a_i[2] & t0x);
    wire t1x = a_i[3] ^ a_i[4];
    wire t1s = t1x ^ a_i[5];
    wire t1c = (a_i[3] & a_i[4]) | (a_i[5] & t1x);
    wire t2x = a_i[6] ^ a_i[7];
    wire t2s = t2x ^ a_i[8];
    wire t2c = (a_i[6] & a_i[7]) | (a_i[8] & t2x);
    wire t3x = a_i[9] ^ a_i[10];
    wire t3s = t3x ^ a_i[11];
    wire t3c = (a_i[9] & a_i[10]) | (a_i[11] & t3x);
    wire t4x = a_i[12] ^ a_i[13];
    wire t4s = t4x ^ a_i[14];
    wire t4c = (a_i[12] & a_i[13]) | (a_i[14] & t4x);
    wire t5x = a_i[15] ^ a_i[16];
    wire t5s = t5x ^ a_i[17];
    wire t5c = (a_i[15] & a_i[16]) | (a_i[17] & t5x);
    wire t6x = a_i[18] ^ a_i[19];
    wire t6s = t6x ^ a_i[20];
    wire t6c = (a_i[18] & a_i[19]) | (a_i[20] & t6x);
    wire t7x = a_i[21] ^ a_i[22];
    wire t7s = t7x ^ a_i[23];
    wire t7c = (a_i[21] & a_i[22]) | (a_i[23] & t7x);
    wire t8x = a_i[24] ^ a_i[25];
    wire t8s = t8x ^ a_i[26];
    wire t8c = (a_i[24] & a_i[25]) | (a_i[26] & t8x);
    wire t9x = a_i[27] ^ a_i[28];
    wire t9s = t9x ^ a_i[29];
    wire t9c = (a_i[27] & a_i[28]) | (a_i[29] & t9x);

    // ---------------- stage 2 -------------------------------------------
    // weight-1 column : t0s..t9s , a30 , a31   (12 bits)
    wire u0x = t0s ^ t1s;
    wire u0s = u0x ^ t2s;
    wire u0c = (t0s & t1s) | (t2s & u0x);
    wire u1x = t3s ^ t4s;
    wire u1s = u1x ^ t5s;
    wire u1c = (t3s & t4s) | (t5s & u1x);
    wire u2x = t6s ^ t7s;
    wire u2s = u2x ^ t8s;
    wire u2c = (t6s & t7s) | (t8s & u2x);
    wire u3x = t9s ^ a_i[30];
    wire u3s = u3x ^ a_i[31];
    wire u3c = (t9s & a_i[30]) | (a_i[31] & u3x);
    // weight-2 column : t0c..t9c  (10 bits, t9c left over)
    wire u4x = t0c ^ t1c;
    wire u4s = u4x ^ t2c;
    wire u4c = (t0c & t1c) | (t2c & u4x);
    wire u5x = t3c ^ t4c;
    wire u5s = u5x ^ t5c;
    wire u5c = (t3c & t4c) | (t5c & u5x);
    wire u6x = t6c ^ t7c;
    wire u6s = u6x ^ t8c;
    wire u6c = (t6c & t7c) | (t8c & u6x);

    // ---------------- stage 3 -------------------------------------------
    wire v0x = u0s ^ u1s;
    wire v0s = v0x ^ u2s;                       // weight 1
    wire v0c = (u0s & u1s) | (u2s & v0x);       // weight 2
    wire v1x = u0c ^ u1c;
    wire v1s = v1x ^ u2c;                       // weight 2
    wire v1c = (u0c & u1c) | (u2c & v1x);       // weight 4
    wire v2x = u3c ^ u4s;
    wire v2s = v2x ^ u5s;                       // weight 2
    wire v2c = (u3c & u4s) | (u5s & v2x);       // weight 4
    wire v3x = u4c ^ u5c;
    wire v3s = v3x ^ u6c;                       // weight 4
    wire v3c = (u4c & u5c) | (u6c & v3x);       // weight 8

    // ---------------- stage 4 -------------------------------------------
    wire w0x = v1s ^ v2s;
    wire w0s = w0x ^ u6s;                       // weight 2
    wire w0c = (v1s & v2s) | (u6s & w0x);       // weight 4
    wire w1s = t9c ^ v0c;                       // weight 2
    wire w1c = t9c & v0c;                       // weight 4
    wire x0x = v3s ^ v1c;
    wire x0s = x0x ^ v2c;                       // weight 4
    wire x0c = (v3s & v1c) | (v2c & x0x);       // weight 8

    // remaining bits per weight
    wire e0 = v0s, e1 = u3s;                    // weight 1
    wire f0 = w0s, f1 = w1s;                    // weight 2
    wire g0 = x0s, g1 = w0c, g2 = w1c;          // weight 4
    wire h0 = v3c, h1 = x0c;                    // weight 8

    // ---------------- final compaction ----------------------------------
    wire k1 = e0 & e1;
    wire b0 = e0 ^ e1;

    wire sf = f0 ^ f1;
    wire b1 = sf ^ k1;
    wire k2 = (f0 & f1) | (sf & k1);

    // V = g0+g1+g2+k2  (0..4)
    wire ps = g0 ^ g1;
    wire pc = g0 & g1;
    wire qs = g2 ^ k2;
    wire qc = g2 & k2;
    wire vm = ps & qs;
    wire pq = pc ^ qc;
    wire V0 = ps ^ qs;
    wire V1 = pq ^ vm;
    wire V2 = (pc & qc) | (pq & vm);

    // T = h0+h1+V1  (0..3)
    wire ts = h0 ^ h1;
    wire T0 = ts ^ V1;
    wire T1 = (h0 & h1) | (ts & V1);

    wire [5:0] total = {T1 & V2, T1 ^ V2, T0, V0, b1, b0};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= total;
    end
end
endmodule
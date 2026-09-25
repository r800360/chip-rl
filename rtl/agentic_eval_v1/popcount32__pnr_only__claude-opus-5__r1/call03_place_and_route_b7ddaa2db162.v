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

    // ---------------- final weighted sum --------------------------------
    // weight 1 : v0s , u3s
    // weight 2 : v0c , v1s , v2s , u6s , t9c
    // weight 4 : v3s , v1c , v2c
    // weight 8 : v3c
    wire [2:0] c2 = v0c + v1s + v2s + u6s + t9c;      // 0..5
    wire [1:0] c4 = v3s + v1c + v2c;                  // 0..3
    wire [5:0] total = v0s + u3s + {c2, 1'b0} + {c4, 2'b0} + {v3c, 3'b0};

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
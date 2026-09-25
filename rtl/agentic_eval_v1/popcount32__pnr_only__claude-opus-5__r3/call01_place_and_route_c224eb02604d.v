module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
    // ---------------- 8 nibble counts (3 bits each) --------------------------
    wire [7:0] x0 = {a_i[28],a_i[24],a_i[20],a_i[16],a_i[12],a_i[8],a_i[4],a_i[0]};
    wire [7:0] x1 = {a_i[29],a_i[25],a_i[21],a_i[17],a_i[13],a_i[9],a_i[5],a_i[1]};
    wire [7:0] x2 = {a_i[30],a_i[26],a_i[22],a_i[18],a_i[14],a_i[10],a_i[6],a_i[2]};
    wire [7:0] x3 = {a_i[31],a_i[27],a_i[23],a_i[19],a_i[15],a_i[11],a_i[7],a_i[3]};

    wire [7:0] hs = x0 ^ x1;
    wire [7:0] hc = x0 & x1;
    wire [7:0] ht = x2 ^ x3;
    wire [7:0] hu = x2 & x3;

    wire [7:0] n0 = hs ^ ht;
    wire [7:0] n1 = (hc ^ hu) ^ (hs & ht);
    wire [7:0] n2 = hc & hu;                 // nibble == 4

    // ---------------- 4 byte counts (4 bits each) ---------------------------
    wire [3:0] a0 = {n0[6],n0[4],n0[2],n0[0]};
    wire [3:0] b0 = {n0[7],n0[5],n0[3],n0[1]};
    wire [3:0] a1 = {n1[6],n1[4],n1[2],n1[0]};
    wire [3:0] b1 = {n1[7],n1[5],n1[3],n1[1]};
    wire [3:0] a2 = {n2[6],n2[4],n2[2],n2[0]};
    wire [3:0] b2 = {n2[7],n2[5],n2[3],n2[1]};

    wire [3:0] B0 = a0 ^ b0;
    wire [3:0] k1 = a0 & b0;
    wire [3:0] B1 = (a1 ^ b1) ^ k1;
    wire [3:0] k2 = (a1 & b1) | (a1 & k1) | (b1 & k1);
    wire [3:0] B2 = (a2 ^ b2) | k2;          // (a2^b2)&k2 == 0
    wire [3:0] B3 = a2 & b2;                 // byte == 8

    // ---------------- 2 half-word counts (5 bits each) ----------------------
    wire [1:0] u0 = {B0[2],B0[0]};
    wire [1:0] v0 = {B0[3],B0[1]};
    wire [1:0] u1 = {B1[2],B1[0]};
    wire [1:0] v1 = {B1[3],B1[1]};
    wire [1:0] u2 = {B2[2],B2[0]};
    wire [1:0] v2 = {B2[3],B2[1]};
    wire [1:0] u3 = {B3[2],B3[0]};
    wire [1:0] v3 = {B3[3],B3[1]};

    wire [1:0] H0 = u0 ^ v0;
    wire [1:0] m1 = u0 & v0;
    wire [1:0] H1 = (u1 ^ v1) ^ m1;
    wire [1:0] m2 = (u1 & v1) | (u1 & m1) | (v1 & m1);
    wire [1:0] H2 = (u2 ^ v2) ^ m2;
    wire [1:0] m3 = (u2 & v2) | (u2 & m2) | (v2 & m2);
    wire [1:0] H3 = (u3 ^ v3) | m3;          // (u3^v3)&m3 == 0
    wire [1:0] H4 = u3 & v3;                 // half == 16

    // ---------------- final 5 + 5 -> 6 --------------------------------------
    wire t0 = H0[0] ^ H0[1];
    wire w1 = H0[0] & H0[1];
    wire t1 = (H1[0] ^ H1[1]) ^ w1;
    wire w2 = (H1[0] & H1[1]) | (H1[0] & w1) | (H1[1] & w1);
    wire t2 = (H2[0] ^ H2[1]) ^ w2;
    wire w3 = (H2[0] & H2[1]) | (H2[0] & w2) | (H2[1] & w2);
    wire t3 = (H3[0] ^ H3[1]) ^ w3;
    wire w4 = (H3[0] & H3[1]) | (H3[0] & w3) | (H3[1] & w3);
    wire t4 = (H4[0] ^ H4[1]) | w4;          // (H4[0]^H4[1])&w4 == 0
    wire t5 = H4[0] & H4[1];                 // all 32 ones

    wire [5:0] total_0 = {t5,t4,t3,t2,t1,t0};

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o <= 6'd0;
        end else begin
            valid_o <= valid_i;
            if (valid_i)
                y_o <= total_0;
        end
    end
endmodule
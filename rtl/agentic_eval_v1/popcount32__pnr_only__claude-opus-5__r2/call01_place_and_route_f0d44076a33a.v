module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// ================= stage A : 10 full adders + 1 half adder ===============
wire [9:0] A0 = {a_i[27],a_i[24],a_i[21],a_i[18],a_i[15],a_i[12],a_i[9],a_i[6],a_i[3],a_i[0]};
wire [9:0] B0 = {a_i[28],a_i[25],a_i[22],a_i[19],a_i[16],a_i[13],a_i[10],a_i[7],a_i[4],a_i[1]};
wire [9:0] D0 = {a_i[29],a_i[26],a_i[23],a_i[20],a_i[17],a_i[14],a_i[11],a_i[8],a_i[5],a_i[2]};
wire [9:0] X0 = A0 ^ B0;
wire [9:0] S  = X0 ^ D0;                 // weight 1, t=2
wire [9:0] C  = (A0 & B0) | (D0 & X0);   // weight 2, t=2
wire Sh = a_i[30] ^ a_i[31];             // weight 1, t=1
wire Ch = a_i[30] & a_i[31];             // weight 2, t=1

// ================= stage B : column weight-1  (11 bits -> 2 rows) ========
wire xu0 = S[0] ^ S[1];
wire u0  = xu0 ^ S[2];
wire k0  = (S[0] & S[1]) | (S[2] & xu0);
wire xu1 = S[3] ^ S[4];
wire u1  = xu1 ^ S[5];
wire k1  = (S[3] & S[4]) | (S[5] & xu1);
wire xu2 = S[6] ^ S[7];
wire u2  = xu2 ^ S[8];
wire k2  = (S[6] & S[7]) | (S[8] & xu2);
wire xu3 = Sh ^ S[9];
wire u3  = xu3 ^ u0;
wire k3  = (Sh & S[9]) | (u0 & xu3);
wire v0  = u1 ^ u2;
wire k4  = u1 & u2;
// weight-1 rows : v0 , u3

// ================= stage C : column weight-2  (16 bits -> 2 rows) ========
wire xm0 = C[0] ^ C[1];
wire m0  = xm0 ^ Ch;
wire n0  = (C[0] & C[1]) | (Ch & xm0);
wire xm1 = C[2] ^ C[3];
wire m1  = xm1 ^ C[4];
wire n1  = (C[2] & C[3]) | (C[4] & xm1);
wire xm2 = C[5] ^ C[6];
wire m2  = xm2 ^ C[7];
wire n2  = (C[5] & C[6]) | (C[7] & xm2);
wire xm3 = C[8] ^ C[9];
wire m3  = xm3 ^ m0;
wire n3  = (C[8] & C[9]) | (m0 & xm3);
wire xm4 = m1 ^ m2;
wire m4  = xm4 ^ k0;
wire n4  = (m1 & m2) | (k0 & xm4);
wire xm5 = k1 ^ k2;
wire m5  = xm5 ^ k3;
wire n5  = (k1 & k2) | (k3 & xm5);
wire xm6 = k4 ^ m3;
wire m6  = xm6 ^ m4;
wire n6  = (k4 & m3) | (m4 & xm6);
// weight-2 rows : m5 , m6

// ================= stage D : column weight-4  (7 bits -> 2 rows) =========
wire xq0 = n0 ^ n1;
wire q0  = xq0 ^ n2;
wire r0  = (n0 & n1) | (n2 & xq0);
wire q1  = n3 ^ n4;
wire r1  = n3 & n4;
wire xq2 = q0 ^ n5;
wire q2  = xq2 ^ q1;
wire r2  = (q0 & n5) | (q1 & xq2);
// weight-4 rows : n6 , q2

// ================= stage E : column weight-8  (3 bits -> 2 rows) =========
wire w0 = r0 ^ r1;
wire e0 = r0 & r1;
// weight-8 rows : w0 , r2   ; weight-16 row : e0

// ================= final 5-bit carry-lookahead addition ==================
wire p0 = v0 ^ u3;
wire g0 = v0 & u3;
wire p1 = m5 ^ m6;
wire g1 = m5 & m6;
wire p2 = n6 ^ q2;
wire g2 = n6 & q2;
wire p3 = w0 ^ r2;
wire g3 = w0 & r2;
wire p4 = e0;

wire c1 = g0;
wire c2 = g1 | (p1 & c1);
wire c3 = g2 | (p2 & c2);
wire c4 = g3 | (p3 & c3);

wire [5:0] total_0;
assign total_0[0] = p0;
assign total_0[1] = p1 ^ c1;
assign total_0[2] = p2 ^ c2;
assign total_0[3] = p3 ^ c3;
assign total_0[4] = p4 ^ c4;
assign total_0[5] = p4 & c4;

// ================= output registers ======================================
wire       en   = rst_n & valid_i;
wire [5:0] hold = y_o & {6{rst_n}};

always @(posedge clk) begin
    valid_o <= en;
    y_o     <= en ? total_0 : hold;
end
endmodule
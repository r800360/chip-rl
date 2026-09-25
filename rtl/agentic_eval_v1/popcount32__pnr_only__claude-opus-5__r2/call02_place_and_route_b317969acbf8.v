module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// ============ eight 4-bit counters : B2 B1 B0 = popcount(a[4j+3:4j]) =====
wire [7:0] ua = {a_i[28],a_i[24],a_i[20],a_i[16],a_i[12],a_i[8], a_i[4],a_i[0]};
wire [7:0] ub = {a_i[29],a_i[25],a_i[21],a_i[17],a_i[13],a_i[9], a_i[5],a_i[1]};
wire [7:0] uc = {a_i[30],a_i[26],a_i[22],a_i[18],a_i[14],a_i[10],a_i[6],a_i[2]};
wire [7:0] ud = {a_i[31],a_i[27],a_i[23],a_i[19],a_i[15],a_i[11],a_i[7],a_i[3]};
wire [7:0] U = ua ^ ub;
wire [7:0] V = ua & ub;
wire [7:0] W = uc ^ ud;
wire [7:0] Z = uc & ud;
wire [7:0] B0 = U ^ W;                  // weight 1
wire [7:0] B1 = (V ^ Z) ^ (U & W);      // weight 2
wire [7:0] B2 = V & Z;                  // weight 4

// ================= column weight-1 : 8 bits -> 2 rows ====================
wire x00 = B0[0] ^ B0[1];
wire s00 = x00 ^ B0[2];
wire c00 = (B0[0] & B0[1]) | (B0[2] & x00);
wire x01 = B0[3] ^ B0[4];
wire s01 = x01 ^ B0[5];
wire c01 = (B0[3] & B0[4]) | (B0[5] & x01);
wire x02 = B0[6] ^ B0[7];
wire s02 = x02 ^ s00;
wire c02 = (B0[6] & B0[7]) | (s00 & x02);

// ================= column weight-2 : 11 bits -> 2 rows ===================
wire x10 = B1[0] ^ B1[1];
wire s10 = x10 ^ B1[2];
wire c10 = (B1[0] & B1[1]) | (B1[2] & x10);
wire x11 = B1[3] ^ B1[4];
wire s11 = x11 ^ B1[5];
wire c11 = (B1[3] & B1[4]) | (B1[5] & x11);
wire x12 = B1[6] ^ B1[7];
wire s12 = x12 ^ c00;
wire c12 = (B1[6] & B1[7]) | (c00 & x12);
wire x13 = c01 ^ s10;
wire s13 = x13 ^ c02;
wire c13 = (c01 & s10) | (c02 & x13);
wire s14 = s11 ^ s12;
wire c14 = s11 & s12;

// ================= column weight-4 : 13 bits -> 2 rows ===================
wire x20 = B2[0] ^ B2[1];
wire s20 = x20 ^ B2[2];
wire c20 = (B2[0] & B2[1]) | (B2[2] & x20);
wire x21 = B2[3] ^ B2[4];
wire s21 = x21 ^ B2[5];
wire c21 = (B2[3] & B2[4]) | (B2[5] & x21);
wire x22 = B2[6] ^ B2[7];
wire s22 = x22 ^ s20;
wire c22 = (B2[6] & B2[7]) | (s20 & x22);
wire x23 = s21 ^ s22;
wire s23 = x23 ^ c10;
wire c23 = (s21 & s22) | (c10 & x23);
wire x24 = c11 ^ c12;
wire s24 = x24 ^ c14;
wire c24 = (c11 & c12) | (c14 & x24);
wire s25 = s23 ^ c13;
wire c25 = s23 & c13;

// ================= column weight-8 : 6 bits -> 2 rows ====================
wire x30 = c20 ^ c21;
wire s30 = x30 ^ c22;
wire c30 = (c20 & c21) | (c22 & x30);
wire x31 = s30 ^ c23;
wire s31 = x31 ^ c24;
wire c31 = (s30 & c23) | (c24 & x31);

// ================= final 5-position carry propagate =====================
wire p0 = s01 ^ s02;
wire g0 = s01 & s02;
wire p1 = s13 ^ s14;
wire g1 = s13 & s14;
wire p2 = s25 ^ s24;
wire g2 = s25 & s24;
wire p3 = s31 ^ c25;
wire g3 = s31 & c25;
wire p4 = c30 ^ c31;
wire g4 = c30 & c31;

wire k1 = g0;
wire k2 = g1 | (p1 & k1);
wire k3 = g2 | (p2 & k2);
wire k4 = g3 | (p3 & k3);
wire k5 = g4 | (p4 & k4);

wire [5:0] total_0;
assign total_0[0] = p0;
assign total_0[1] = p1 ^ k1;
assign total_0[2] = p2 ^ k2;
assign total_0[3] = p3 ^ k3;
assign total_0[4] = p4 ^ k4;
assign total_0[5] = k5;

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
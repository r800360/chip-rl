module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// ---------------- stage 1 : ten full adders on a_i[29:0] ----------------
wire [9:0] f1a = {a_i[27],a_i[24],a_i[21],a_i[18],a_i[15],a_i[12],a_i[9],a_i[6],a_i[3],a_i[0]};
wire [9:0] f1b = {a_i[28],a_i[25],a_i[22],a_i[19],a_i[16],a_i[13],a_i[10],a_i[7],a_i[4],a_i[1]};
wire [9:0] f1c = {a_i[29],a_i[26],a_i[23],a_i[20],a_i[17],a_i[14],a_i[11],a_i[8],a_i[5],a_i[2]};
wire [9:0] f1x = f1a ^ f1b;
wire [9:0] s1  = f1x ^ f1c;
wire [9:0] c1  = (f1a & f1b) | (f1c & f1x);
// leftovers at weight1 : a_i[30], a_i[31]

// ---------------- stage 2 : weight-1 column (12 bits -> 4 FA) ------------
wire [3:0] f2a = {s1[9],   s1[6], s1[3], s1[0]};
wire [3:0] f2b = {a_i[30], s1[7], s1[4], s1[1]};
wire [3:0] f2c = {a_i[31], s1[8], s1[5], s1[2]};
wire [3:0] f2x = f2a ^ f2b;
wire [3:0] s2  = f2x ^ f2c;          // weight 1
wire [3:0] c2  = (f2a & f2b) | (f2c & f2x);   // weight 2

// ---------------- stage 2 : weight-2 column (10 bits -> 3 FA) ------------
wire [2:0] g2a = {c1[6],c1[3],c1[0]};
wire [2:0] g2b = {c1[7],c1[4],c1[1]};
wire [2:0] g2c = {c1[8],c1[5],c1[2]};
wire [2:0] g2x = g2a ^ g2b;
wire [2:0] t2  = g2x ^ g2c;          // weight 2
wire [2:0] d2  = (g2a & g2b) | (g2c & g2x);   // weight 4
// leftover weight2 : c1[9]

// ---------------- stage 3 ------------------------------------------------
// weight1 : FA(s2[0],s2[1],s2[2]) , leftover s2[3]
wire x3   = s2[0] ^ s2[1];
wire s3   = x3 ^ s2[2];                          // weight1 row A
wire c3   = (s2[0] & s2[1]) | (s2[2] & x3);      // weight2

// weight2 : FA(t2), FA(c2[2:0]), HA(c1[9],c2[3])
wire xa   = t2[0] ^ t2[1];
wire u3_0 = xa ^ t2[2];
wire v3_0 = (t2[0] & t2[1]) | (t2[2] & xa);
wire xb   = c2[0] ^ c2[1];
wire u3_1 = xb ^ c2[2];
wire v3_1 = (c2[0] & c2[1]) | (c2[2] & xb);
wire u3_2 = c1[9] ^ c2[3];
wire v3_2 = c1[9] & c2[3];

// weight4 : FA(d2)
wire xc    = d2[0] ^ d2[1];
wire s3w2  = xc ^ d2[2];                         // weight4
wire c3w2  = (d2[0] & d2[1]) | (d2[2] & xc);     // weight8

// ---------------- stage 4 ------------------------------------------------
wire xd   = u3_0 ^ u3_1;
wire p4a  = xd ^ u3_2;                           // weight2 row A
wire q4a  = (u3_0 & u3_1) | (u3_2 & xd);         // weight4

wire xe   = s3w2 ^ v3_0;
wire p4b  = xe ^ v3_1;                           // weight4
wire q4b  = (s3w2 & v3_0) | (v3_1 & xe);         // weight8

// ---------------- stage 5 ------------------------------------------------
wire xf   = p4b ^ v3_2;
wire p5   = xf ^ q4a;                            // weight4 row A
wire q5   = (p4b & v3_2) | (q4a & xf);           // weight8 row B

wire h5   = c3w2 ^ q4b;                          // weight8 row A
wire g5   = c3w2 & q4b;                          // weight16 row A

// ---------------- final carry-lookahead add of the two rows --------------
// A = {g5, h5, p5, p4a, s3}   B = {0, q5, 0, c3, s2[3]}
wire k0  = s3 & s2[3];
wire pp1 = p4a ^ c3;
wire gg1 = p4a & c3;
wire k1  = gg1 | (pp1 & k0);
wire k2  = p5 & k1;
wire pp3 = h5 ^ q5;
wire gg3 = h5 & q5;
wire k3  = gg3 | (pp3 & k2);

wire [5:0] total_0;
assign total_0[0] = s3  ^ s2[3];
assign total_0[1] = pp1 ^ k0;
assign total_0[2] = p5  ^ k1;
assign total_0[3] = pp3 ^ k2;
assign total_0[4] = g5  ^ k3;
assign total_0[5] = g5  & k3;

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
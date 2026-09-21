module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg          valid_o,
    output reg  [15:0] y_o
);

    wire [15:0] p0, g0;
    assign p0 = a_i ^ b_i;
    assign g0 = a_i & b_i;

    // ---- Up-sweep stage 1 (d=1): nodes 1,3,5,7,9,11,13,15 ----
    wire G1_1,P1_1, G1_3,P1_3, G1_5,P1_5, G1_7,P1_7;
    wire G1_9,P1_9, G1_11,P1_11, G1_13,P1_13, G1_15,P1_15;

    assign G1_1  = g0[1]  | (p0[1]  & g0[0]);
    assign P1_1  = p0[1]  & p0[0];
    assign G1_3  = g0[3]  | (p0[3]  & g0[2]);
    assign P1_3  = p0[3]  & p0[2];
    assign G1_5  = g0[5]  | (p0[5]  & g0[4]);
    assign P1_5  = p0[5]  & p0[4];
    assign G1_7  = g0[7]  | (p0[7]  & g0[6]);
    assign P1_7  = p0[7]  & p0[6];
    assign G1_9  = g0[9]  | (p0[9]  & g0[8]);
    assign P1_9  = p0[9]  & p0[8];
    assign G1_11 = g0[11] | (p0[11] & g0[10]);
    assign P1_11 = p0[11] & p0[10];
    assign G1_13 = g0[13] | (p0[13] & g0[12]);
    assign P1_13 = p0[13] & p0[12];
    assign G1_15 = g0[15] | (p0[15] & g0[14]);
    assign P1_15 = p0[15] & p0[14];

    // ---- Up-sweep stage 2 (d=2): nodes 3,7,11,15 ----
    wire G2_3,P2_3, G2_7,P2_7, G2_11,P2_11, G2_15,P2_15;

    assign G2_3  = G1_3  | (P1_3  & G1_1);
    assign P2_3  = P1_3  & P1_1;
    assign G2_7  = G1_7  | (P1_7  & G1_5);
    assign P2_7  = P1_7  & P1_5;
    assign G2_11 = G1_11 | (P1_11 & G1_9);
    assign P2_11 = P1_11 & P1_9;
    assign G2_15 = G1_15 | (P1_15 & G1_13);
    assign P2_15 = P1_15 & P1_13;

    // ---- Up-sweep stage 3 (d=4): nodes 7,15 ----
    wire G3_7,P3_7, G3_15,P3_15;

    assign G3_7  = G2_7  | (P2_7  & G2_3);
    assign P3_7  = P2_7  & P2_3;
    assign G3_15 = G2_15 | (P2_15 & G2_11);
    assign P3_15 = P2_15 & P2_11;

    // ---- Up-sweep stage 4 (d=8): node 15 (final overall carry, unused for sum) ----
    wire G4_15, P4_15;
    assign G4_15 = G3_15 | (P3_15 & G3_7);
    assign P4_15 = P3_15 & P3_7;

    // ---- Down-sweep d=4: node 11 ----
    wire Gd_11, Pd_11;
    assign Gd_11 = G2_11 | (P2_11 & G3_7);
    assign Pd_11 = P2_11 & P3_7;

    // ---- Down-sweep d=2: nodes 5,9,13 ----
    wire Gd_5,Pd_5, Gd_9,Pd_9, Gd_13,Pd_13;

    assign Gd_5  = G1_5  | (P1_5  & G2_3);
    assign Pd_5  = P1_5  & P2_3;
    assign Gd_9  = G1_9  | (P1_9  & G3_7);
    assign Pd_9  = P1_9  & P3_7;
    assign Gd_13 = G1_13 | (P1_13 & Gd_11);
    assign Pd_13 = P1_13 & Pd_11;

    // ---- Down-sweep d=1: nodes 2,4,6,8,10,12,14 ----
    wire Gd_2,Pd_2, Gd_4,Pd_4, Gd_6,Pd_6, Gd_8,Pd_8;
    wire Gd_10,Pd_10, Gd_12,Pd_12, Gd_14,Pd_14;

    assign Gd_2  = g0[2]  | (p0[2]  & G1_1);
    assign Pd_2  = p0[2]  & P1_1;
    assign Gd_4  = g0[4]  | (p0[4]  & G2_3);
    assign Pd_4  = p0[4]  & P2_3;
    assign Gd_6  = g0[6]  | (p0[6]  & Gd_5);
    assign Pd_6  = p0[6]  & Pd_5;
    assign Gd_8  = g0[8]  | (p0[8]  & G3_7);
    assign Pd_8  = p0[8]  & P3_7;
    assign Gd_10 = g0[10] | (p0[10] & Gd_9);
    assign Pd_10 = p0[10] & Pd_9;
    assign Gd_12 = g0[12] | (p0[12] & Gd_11);
    assign Pd_12 = p0[12] & Pd_11;
    assign Gd_14 = g0[14] | (p0[14] & Gd_13);
    assign Pd_14 = p0[14] & Pd_13;

    // ---- Carries into each bit (overall cin = 0) ----
    wire [14:0] c;
    assign c[0]  = g0[0];
    assign c[1]  = G1_1;
    assign c[2]  = Gd_2;
    assign c[3]  = G2_3;
    assign c[4]  = Gd_4;
    assign c[5]  = Gd_5;
    assign c[6]  = Gd_6;
    assign c[7]  = G3_7;
    assign c[8]  = Gd_8;
    assign c[9]  = Gd_9;
    assign c[10] = Gd_10;
    assign c[11] = Gd_11;
    assign c[12] = Gd_12;
    assign c[13] = Gd_13;
    assign c[14] = Gd_14;

    // ---- Sum bits ----
    wire [15:0] sum;
    assign sum[0]  = p0[0];
    assign sum[1]  = p0[1]  ^ c[0];
    assign sum[2]  = p0[2]  ^ c[1];
    assign sum[3]  = p0[3]  ^ c[2];
    assign sum[4]  = p0[4]  ^ c[3];
    assign sum[5]  = p0[5]  ^ c[4];
    assign sum[6]  = p0[6]  ^ c[5];
    assign sum[7]  = p0[7]  ^ c[6];
    assign sum[8]  = p0[8]  ^ c[7];
    assign sum[9]  = p0[9]  ^ c[8];
    assign sum[10] = p0[10] ^ c[9];
    assign sum[11] = p0[11] ^ c[10];
    assign sum[12] = p0[12] ^ c[11];
    assign sum[13] = p0[13] ^ c[12];
    assign sum[14] = p0[14] ^ c[13];
    assign sum[15] = p0[15] ^ c[14];

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o     <= 16'd0;
        end else begin
            valid_o <= valid_i;

            if (valid_i)
                y_o <= sum;
        end
    end

endmodule

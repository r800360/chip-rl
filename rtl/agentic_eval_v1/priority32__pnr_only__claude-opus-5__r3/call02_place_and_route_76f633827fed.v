module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// ---- level 1 : pair ORs (every a_i bit drives exactly one of these) -------
wire q0  = a_i[1]  | a_i[0];
wire q1  = a_i[3]  | a_i[2];
wire q2  = a_i[5]  | a_i[4];
wire q3  = a_i[7]  | a_i[6];
wire q4  = a_i[9]  | a_i[8];
wire q5  = a_i[11] | a_i[10];
wire q6  = a_i[13] | a_i[12];
wire q7  = a_i[15] | a_i[14];
wire q8  = a_i[17] | a_i[16];
wire q9  = a_i[19] | a_i[18];
wire q10 = a_i[21] | a_i[20];
wire q11 = a_i[23] | a_i[22];
wire q12 = a_i[25] | a_i[24];
wire q13 = a_i[27] | a_i[26];
wire q14 = a_i[29] | a_i[28];
wire q15 = a_i[31] | a_i[30];

// ---- level 2 : byte ORs ---------------------------------------------------
wire b0 = (q0 | q1) | (q2 | q3);
wire b1 = (q4 | q5) | (q6 | q7);
wire b2 = (q8 | q9) | (q10 | q11);
wire b3 = (q12 | q13) | (q14 | q15);

// within-byte pair-index bits (winner pair inside each byte)
wire uu0 = q3  | q2;
wire uu1 = q7  | q6;
wire uu2 = q11 | q10;
wire uu3 = q15 | q14;

wire vv0 = q3  | (~q2  & q1);
wire vv1 = q7  | (~q6  & q5);
wire vv2 = q11 | (~q10 & q9);
wire vv3 = q15 | (~q14 & q13);

// odd-bit of the winning pair inside each byte (odd a_i bits: 2nd load)
wire w0 = a_i[7]  | (~q3  & a_i[5])  | (~q3  & ~q2  & a_i[3])  | (~q3  & ~q2  & ~q1  & a_i[1]);
wire w1 = a_i[15] | (~q7  & a_i[13]) | (~q7  & ~q6  & a_i[11]) | (~q7  & ~q6  & ~q5  & a_i[9]);
wire w2 = a_i[23] | (~q11 & a_i[21]) | (~q11 & ~q10 & a_i[19]) | (~q11 & ~q10 & ~q9  & a_i[17]);
wire w3 = a_i[31] | (~q15 & a_i[29]) | (~q15 & ~q14 & a_i[27]) | (~q15 & ~q14 & ~q13 & a_i[25]);

// ---- output bits ----------------------------------------------------------
wire i4 = b3 | b2;
wire i3 = b3 | (b1 & ~b2 & ~b3);
wire i2 = uu3 | (uu2 & ~b3) | (uu1 & ~b3 & ~b2) | (uu0 & ~b3 & ~b2 & ~b1);
wire i1 = vv3 | (vv2 & ~b3) | (vv1 & ~b3 & ~b2) | (vv0 & ~b3 & ~b2 & ~b1);
wire i0 = w3  | (w2  & ~b3) | (w1  & ~b3 & ~b2) | (w0  & ~b3 & ~b2 & ~b1);
wire hit_0 = (b3 | b2) | (b1 | b0);

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

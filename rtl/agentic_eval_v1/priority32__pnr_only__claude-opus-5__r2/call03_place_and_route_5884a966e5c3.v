module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// ---- level 1: per 4-bit group pair-ORs ----
wire [7:0] H, L, Q, O;

assign H[0] = a_i[3]  | a_i[2];
assign L[0] = a_i[1]  | a_i[0];
assign O[0] = a_i[3]  | (~a_i[2]  & a_i[1]);
assign H[1] = a_i[7]  | a_i[6];
assign L[1] = a_i[5]  | a_i[4];
assign O[1] = a_i[7]  | (~a_i[6]  & a_i[5]);
assign H[2] = a_i[11] | a_i[10];
assign L[2] = a_i[9]  | a_i[8];
assign O[2] = a_i[11] | (~a_i[10] & a_i[9]);
assign H[3] = a_i[15] | a_i[14];
assign L[3] = a_i[13] | a_i[12];
assign O[3] = a_i[15] | (~a_i[14] & a_i[13]);
assign H[4] = a_i[19] | a_i[18];
assign L[4] = a_i[17] | a_i[16];
assign O[4] = a_i[19] | (~a_i[18] & a_i[17]);
assign H[5] = a_i[23] | a_i[22];
assign L[5] = a_i[21] | a_i[20];
assign O[5] = a_i[23] | (~a_i[22] & a_i[21]);
assign H[6] = a_i[27] | a_i[26];
assign L[6] = a_i[25] | a_i[24];
assign O[6] = a_i[27] | (~a_i[26] & a_i[25]);
assign H[7] = a_i[31] | a_i[30];
assign L[7] = a_i[29] | a_i[28];
assign O[7] = a_i[31] | (~a_i[30] & a_i[29]);

// ---- level 2: 4-bit and 8-bit "any set" ----
assign Q = H | L;

wire [3:0] P;
assign P[0] = H[1] | L[1] | H[0] | L[0];
assign P[1] = H[3] | L[3] | H[2] | L[2];
assign P[2] = H[5] | L[5] | H[4] | L[4];
assign P[3] = H[7] | L[7] | H[6] | L[6];

wire R1 = P[3] | P[2];
wire R0 = P[1] | P[0];

// ---- partial results (each output bit is A | (mask & B)) ----
wire y2h = Q[7] | (~P[3] & Q[5]);
wire y2l = Q[3] | (~P[1] & Q[1]);

wire t1_0 = H[1] | (~L[1] & H[0]);
wire t1_1 = H[3] | (~L[3] & H[2]);
wire t1_2 = H[5] | (~L[5] & H[4]);
wire t1_3 = H[7] | (~L[7] & H[6]);
wire u1_0 = t1_1 | (~P[1] & t1_0);
wire u1_1 = t1_3 | (~P[3] & t1_2);

wire t0_0 = O[1] | (~Q[1] & O[0]);
wire t0_1 = O[3] | (~Q[3] & O[2]);
wire t0_2 = O[5] | (~Q[5] & O[4]);
wire t0_3 = O[7] | (~Q[7] & O[6]);
wire u0_0 = t0_1 | (~P[1] & t0_0);
wire u0_1 = t0_3 | (~P[3] & t0_2);

// ---- register control terms (off the a_i path) ----
wire en   = rst_n & valid_i;
wire hold = rst_n & ~valid_i;
wire [5:0] hq = y_o & {6{hold}};
wire enM  = en & ~P[3] & ~P[2];
wire enP  = en & ~P[2];

// ---- flop inputs: last logic level merged with enable/reset ----
wire d5 = (en  & R1)    | (en  & R0)    | hq[5];
wire d4 = (en  & P[3])  | (en  & P[2])  | hq[4];
wire d3 = (en  & P[3])  | (enP & P[1])  | hq[3];
wire d2 = (en  & y2h)   | (enM & y2l)   | hq[2];
wire d1 = (en  & u1_1)  | (enM & u1_0)  | hq[1];
wire d0 = (en  & u0_1)  | (enM & u0_0)  | hq[0];

always @(posedge clk) begin
    valid_o <= en;
    y_o <= {d5, d4, d3, d2, d1, d0};
end
endmodule
module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// ---- nibble occupancy (depth 1) ----
wire nA = |a_i[31:28];
wire nB = |a_i[27:24];
wire nC = |a_i[23:20];
wire nD = |a_i[19:16];
wire nE = |a_i[15:12];
wire nF = |a_i[11:8];
wire nG = |a_i[7:4];
wire nH = |a_i[3:0];

wire hit = nA | nB | nC | nD | nE | nF | nG | nH;

// ---- nibble index bits (depth 2..4) ----
wire s2 = nA | nB | nC | nD;                                     // idx[4]
wire s1 = (nA | nB) | (~(nC | nD) & (nE | nF));                  // idx[3]
wire s0 = nA | (~nB & nC)
             | (~(nB | nC | nD) & nE)
             | (~(nB | nC | nD) & ~(nE | nF) & nG);              // idx[2]

// ---- per-nibble low index bits, all in parallel (depth 1..2) ----
wire [15:0] q;
assign q[1]  = a_i[3]  | a_i[2];
assign q[0]  = a_i[3]  | (~a_i[2]  & a_i[1]);
assign q[3]  = a_i[7]  | a_i[6];
assign q[2]  = a_i[7]  | (~a_i[6]  & a_i[5]);
assign q[5]  = a_i[11] | a_i[10];
assign q[4]  = a_i[11] | (~a_i[10] & a_i[9]);
assign q[7]  = a_i[15] | a_i[14];
assign q[6]  = a_i[15] | (~a_i[14] & a_i[13]);
assign q[9]  = a_i[19] | a_i[18];
assign q[8]  = a_i[19] | (~a_i[18] & a_i[17]);
assign q[11] = a_i[23] | a_i[22];
assign q[10] = a_i[23] | (~a_i[22] & a_i[21]);
assign q[13] = a_i[27] | a_i[26];
assign q[12] = a_i[27] | (~a_i[26] & a_i[25]);
assign q[15] = a_i[31] | a_i[30];
assign q[14] = a_i[31] | (~a_i[30] & a_i[29]);

// ---- 8:1 select of the 2-bit low index ----
wire [7:0] w2 = s2 ? q[15:8]  : q[7:0];
wire [3:0] w1 = s1 ? w2[7:4]  : w2[3:0];
wire [1:0] w0 = s0 ? w1[3:2]  : w1[1:0];

wire [5:0] chosen = {hit, s2, s1, s0, w0[1], w0[0]};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen;
    end
end
endmodule
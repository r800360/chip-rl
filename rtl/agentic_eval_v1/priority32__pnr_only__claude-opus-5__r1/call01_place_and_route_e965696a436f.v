module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// ---- level 1 : nibble occupancy ----
wire n0 = |a_i[3:0];
wire n1 = |a_i[7:4];
wire n2 = |a_i[11:8];
wire n3 = |a_i[15:12];
wire n4 = |a_i[19:16];
wire n5 = |a_i[23:20];
wire n6 = |a_i[27:24];
wire n7 = |a_i[31:28];

// ---- level 2/3/4 : nibble index bits ----
wire hi  = n7 | n6 | n5 | n4;                       // idx[4]
wire lo  = n3 | n2 | n1 | n0;
wire hit = hi | lo;

wire ab  = n7 | n6;
wire cd  = n5 | n4;
wire ef  = n3 | n2;
wire s1  = ab | (~cd & ef);                         // idx[3]

wire t3  = ~(n6 | n5 | n4);
wire t5  = ~(n3 | n2);
wire s0  = n7 | (~n6 & n5) | (t3 & n3) | (t3 & t5 & n1);   // idx[2]

// ---- level 1/2 : per-nibble low index bits (parallel) ----
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

// ---- 8:1 selection, selects applied in arrival order ----
wire [7:0] w2 = hi ? q[15:8] : q[7:0];
wire [3:0] w1 = s1 ? w2[7:4] : w2[3:0];
wire [1:0] w0 = s0 ? w1[3:2] : w1[1:0];

wire [5:0] chosen = {hit, hi, s1, s0, w0[1], w0[0]};

// ---- register tail : only one gate after 'chosen' ----
wire ve = rst_n & valid_i;
wire [5:0] hold = rst_n ? y_o : 6'd0;

always @(posedge clk) begin
    valid_o <= ve;
    y_o     <= ve ? chosen : hold;
end

endmodule
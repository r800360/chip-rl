module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire [31:0] e = ~(a_i ^ b_i);
wire [31:0] g = (~a_i) & b_i;

// ---- 16 two-bit primitives (one complex gate each, uniform depth) ----
wire [15:0] l1, q1;
assign l1[ 0] = g[ 1] | (e[ 1] & g[ 0]);  assign q1[ 0] = e[ 1] & e[ 0];
assign l1[ 1] = g[ 3] | (e[ 3] & g[ 2]);  assign q1[ 1] = e[ 3] & e[ 2];
assign l1[ 2] = g[ 5] | (e[ 5] & g[ 4]);  assign q1[ 2] = e[ 5] & e[ 4];
assign l1[ 3] = g[ 7] | (e[ 7] & g[ 6]);  assign q1[ 3] = e[ 7] & e[ 6];
assign l1[ 4] = g[ 9] | (e[ 9] & g[ 8]);  assign q1[ 4] = e[ 9] & e[ 8];
assign l1[ 5] = g[11] | (e[11] & g[10]);  assign q1[ 5] = e[11] & e[10];
assign l1[ 6] = g[13] | (e[13] & g[12]);  assign q1[ 6] = e[13] & e[12];
assign l1[ 7] = g[15] | (e[15] & g[14]);  assign q1[ 7] = e[15] & e[14];
assign l1[ 8] = g[17] | (e[17] & g[16]);  assign q1[ 8] = e[17] & e[16];
assign l1[ 9] = g[19] | (e[19] & g[18]);  assign q1[ 9] = e[19] & e[18];
assign l1[10] = g[21] | (e[21] & g[20]);  assign q1[10] = e[21] & e[20];
assign l1[11] = g[23] | (e[23] & g[22]);  assign q1[11] = e[23] & e[22];
assign l1[12] = g[25] | (e[25] & g[24]);  assign q1[12] = e[25] & e[24];
assign l1[13] = g[27] | (e[27] & g[26]);  assign q1[13] = e[27] & e[26];
assign l1[14] = g[29] | (e[29] & g[28]);  assign q1[14] = e[29] & e[28];
assign l1[15] = g[31] | (e[31] & g[30]);  assign q1[15] = e[31] & e[30];

// ---- 4-way merge : 16 -> 4 (each covers 8 bits) ----
wire [3:0] l2, q2;

assign l2[0] = l1[3] | (q1[3] & l1[2]) | (q1[3] & q1[2] & l1[1]) | (q1[3] & q1[2] & q1[1] & l1[0]);
assign q2[0] = q1[3] & q1[2] & q1[1] & q1[0];
assign l2[1] = l1[7] | (q1[7] & l1[6]) | (q1[7] & q1[6] & l1[5]) | (q1[7] & q1[6] & q1[5] & l1[4]);
assign q2[1] = q1[7] & q1[6] & q1[5] & q1[4];
assign l2[2] = l1[11] | (q1[11] & l1[10]) | (q1[11] & q1[10] & l1[9]) | (q1[11] & q1[10] & q1[9] & l1[8]);
assign q2[2] = q1[11] & q1[10] & q1[9] & q1[8];
assign l2[3] = l1[15] | (q1[15] & l1[14]) | (q1[15] & q1[14] & l1[13]) | (q1[15] & q1[14] & q1[13] & l1[12]);
assign q2[3] = q1[15] & q1[14] & q1[13] & q1[12];

// ---- top 4-way merge with the enable mux folded in ----
wire v3  = valid_i & q2[3];
wire v32 = valid_i & q2[3] & q2[2];
wire v31 = valid_i & q2[3] & q2[2] & q2[1];

wire y_next = (valid_i & l2[3]) | (v3 & l2[2]) | (v32 & l2[1]) | (v31 & l2[0]) | ((~valid_i) & y_o);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        y_o <= y_next;
    end
end
endmodule

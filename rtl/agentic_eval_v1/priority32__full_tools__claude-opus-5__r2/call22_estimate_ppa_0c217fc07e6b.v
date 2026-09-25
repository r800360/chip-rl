module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [7:0] A;
assign A[0] = |a_i[3:0];
assign A[1] = |a_i[7:4];
assign A[2] = |a_i[11:8];
assign A[3] = |a_i[15:12];
assign A[4] = |a_i[19:16];
assign A[5] = |a_i[23:20];
assign A[6] = |a_i[27:24];
assign A[7] = |a_i[31:28];
wire [7:0] n;
assign n[7] = 1'b1;
assign n[6] = ~A[7];
assign n[5] = ~A[7] & ~A[6];
assign n[4] = ~A[7] & ~A[6] & ~A[5];
assign n[3] = ~A[7] & ~A[6] & ~A[5] & ~A[4];
assign n[2] = ~A[7] & ~A[6] & ~A[5] & ~A[4] & ~A[3];
assign n[1] = ~A[7] & ~A[6] & ~A[5] & ~A[4] & ~A[3] & ~A[2];
assign n[0] = ~A[7] & ~A[6] & ~A[5] & ~A[4] & ~A[3] & ~A[2] & ~A[1];
wire [7:0] L1, L0;
assign L1[0] = a_i[3] | a_i[2];
assign L0[0] = a_i[3] | (a_i[1] & ~a_i[2]);
assign L1[1] = a_i[7] | a_i[6];
assign L0[1] = a_i[7] | (a_i[5] & ~a_i[6]);
assign L1[2] = a_i[11] | a_i[10];
assign L0[2] = a_i[11] | (a_i[9] & ~a_i[10]);
assign L1[3] = a_i[15] | a_i[14];
assign L0[3] = a_i[15] | (a_i[13] & ~a_i[14]);
assign L1[4] = a_i[19] | a_i[18];
assign L0[4] = a_i[19] | (a_i[17] & ~a_i[18]);
assign L1[5] = a_i[23] | a_i[22];
assign L0[5] = a_i[23] | (a_i[21] & ~a_i[22]);
assign L1[6] = a_i[27] | a_i[26];
assign L0[6] = a_i[27] | (a_i[25] & ~a_i[26]);
assign L1[7] = a_i[31] | a_i[30];
assign L0[7] = a_i[31] | (a_i[29] & ~a_i[30]);
wire y4 = A[7] | A[6] | A[5] | A[4];
wire y3 = A[7] | A[6] | (A[3] & n[3]) | (A[2] & n[3]);
wire y2 = A[7] | (A[5] & n[5]) | (A[3] & n[3]) | (A[1] & n[1]);
wire y1 = (L1[7]) | (L1[6] & n[6]) | (L1[5] & n[5]) | (L1[4] & n[4])
        | (L1[3] & n[3]) | (L1[2] & n[2]) | (L1[1] & n[1]) | (L1[0] & n[0]);
wire y0 = (L0[7]) | (L0[6] & n[6]) | (L0[5] & n[5]) | (L0[4] & n[4])
        | (L0[3] & n[3]) | (L0[2] & n[2]) | (L0[1] & n[1]) | (L0[0] & n[0]);
wire hit = |A;
wire [5:0] chosen = {hit, y4, y3, y2, y1, y0};
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
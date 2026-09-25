module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// group-of-4 structure
wire [7:0] c;
assign c[0] = |a_i[3:0];
assign c[1] = |a_i[7:4];
assign c[2] = |a_i[11:8];
assign c[3] = |a_i[15:12];
assign c[4] = |a_i[19:16];
assign c[5] = |a_i[23:20];
assign c[6] = |a_i[27:24];
assign c[7] = |a_i[31:28];

// suffix nor: n[j] = ~(|c[7:j])
wire n7 = ~c[7];
wire n6 = ~(c[7]|c[6]);
wire n5 = ~(c[7]|c[6]|c[5]);
wire n4 = ~(c[7]|c[6]|c[5]|c[4]);
wire n3 = n4 & ~c[3];
wire n2 = n4 & ~(c[3]|c[2]);
wire n1 = n4 & ~(c[3]|c[2]|c[1]);
wire hit = ~(n1 & ~c[0]);

// upper pair of each group
wire [7:0] e;
assign e[0] = a_i[3] | a_i[2];
assign e[1] = a_i[7] | a_i[6];
assign e[2] = a_i[11]| a_i[10];
assign e[3] = a_i[15]| a_i[14];
assign e[4] = a_i[19]| a_i[18];
assign e[5] = a_i[23]| a_i[22];
assign e[6] = a_i[27]| a_i[26];
assign e[7] = a_i[31]| a_i[30];

// odd bit within group: d[j] = a[4j+3] | (a[4j+1] & ~a[4j+2])
wire [7:0] d;
assign d[0] = a_i[3]  | (a_i[1]  & ~a_i[2]);
assign d[1] = a_i[7]  | (a_i[5]  & ~a_i[6]);
assign d[2] = a_i[11] | (a_i[9]  & ~a_i[10]);
assign d[3] = a_i[15] | (a_i[13] & ~a_i[14]);
assign d[4] = a_i[19] | (a_i[17] & ~a_i[18]);
assign d[5] = a_i[23] | (a_i[21] & ~a_i[22]);
assign d[6] = a_i[27] | (a_i[25] & ~a_i[26]);
assign d[7] = a_i[31] | (a_i[29] & ~a_i[30]);

wire [5:0] chosen;
assign chosen[5] = hit;
assign chosen[4] = ~n4;
assign chosen[3] = (c[7]|c[6]) | (~c[5] & ~c[4] & (c[3]|c[2]));
assign chosen[2] = c[7] | (c[5] & ~c[6]) | (c[3] & ~c[4] & ~c[6]) | (c[1] & ~c[2] & ~c[4] & ~c[6]);
assign chosen[1] = e[7] | (e[6]&n7) | (e[5]&n6) | (e[4]&n5) |
                   (e[3]&n4) | (e[2]&n3) | (e[1]&n2) | (e[0]&n1);
assign chosen[0] = d[7] | (d[6]&n7) | (d[5]&n6) | (d[4]&n5) |
                   (d[3]&n4) | (d[2]&n3) | (d[1]&n2) | (d[0]&n1);

wire wen = rst_n & valid_i;
always @(posedge clk) begin
    valid_o <= wen;
    y_o <= wen ? chosen : (y_o & {6{rst_n}});
end
endmodule
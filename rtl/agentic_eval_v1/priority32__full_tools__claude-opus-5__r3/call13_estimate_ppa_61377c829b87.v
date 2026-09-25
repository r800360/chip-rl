module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [15:0] q;
assign q[0]=a_i[1]|a_i[0];   assign q[1]=a_i[3]|a_i[2];
assign q[2]=a_i[5]|a_i[4];   assign q[3]=a_i[7]|a_i[6];
assign q[4]=a_i[9]|a_i[8];   assign q[5]=a_i[11]|a_i[10];
assign q[6]=a_i[13]|a_i[12]; assign q[7]=a_i[15]|a_i[14];
assign q[8]=a_i[17]|a_i[16]; assign q[9]=a_i[19]|a_i[18];
assign q[10]=a_i[21]|a_i[20];assign q[11]=a_i[23]|a_i[22];
assign q[12]=a_i[25]|a_i[24];assign q[13]=a_i[27]|a_i[26];
assign q[14]=a_i[29]|a_i[28];assign q[15]=a_i[31]|a_i[30];

wire [15:0] t1 = q  | {1'b0, q[15:1]};
wire [15:0] t2 = t1 | {2'b0, t1[15:2]};
wire [15:0] t4 = t2 | {4'b0, t2[15:4]};
wire [15:0] M  = t4 | {8'b0, t4[15:8]};

wire [5:0] chosen;
assign chosen[5] = |a_i;
assign chosen[4] = |a_i[31:16];
assign chosen[3] = M[12] | (M[4] & ~M[8]);
assign chosen[2] = M[14] | (M[10]&~M[12]) | (M[6]&~M[8]) | (M[2]&~M[4]);
assign chosen[1] = M[15] | (M[13]&~M[14]) | (M[11]&~M[12]) | (M[9]&~M[10]) |
                   (M[7]&~M[8]) | (M[5]&~M[6]) | (M[3]&~M[4]) | (M[1]&~M[2]);
assign chosen[0] = a_i[31] | (a_i[29]&~M[15]) | (a_i[27]&~M[14]) | (a_i[25]&~M[13]) |
                   (a_i[23]&~M[12]) | (a_i[21]&~M[11]) | (a_i[19]&~M[10]) | (a_i[17]&~M[9]) |
                   (a_i[15]&~M[8])  | (a_i[13]&~M[7])  | (a_i[11]&~M[6])  | (a_i[9]&~M[5]) |
                   (a_i[7]&~M[4])   | (a_i[5]&~M[3])   | (a_i[3]&~M[2])   | (a_i[1]&~M[1]);

wire wen = rst_n & valid_i;
always @(posedge clk) begin
    valid_o <= wen;
    y_o <= wen ? chosen : (y_o & {6{rst_n}});
end
endmodule
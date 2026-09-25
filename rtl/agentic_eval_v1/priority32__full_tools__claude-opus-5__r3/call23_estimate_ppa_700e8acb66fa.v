module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
// sparse prefix over 8 groups of 4
wire [7:0] c;
assign c[0]=(a_i[1]|a_i[0])|(a_i[3]|a_i[2]);
assign c[1]=(a_i[5]|a_i[4])|(a_i[7]|a_i[6]);
assign c[2]=(a_i[9]|a_i[8])|(a_i[11]|a_i[10]);
assign c[3]=(a_i[13]|a_i[12])|(a_i[15]|a_i[14]);
assign c[4]=(a_i[17]|a_i[16])|(a_i[19]|a_i[18]);
assign c[5]=(a_i[21]|a_i[20])|(a_i[23]|a_i[22]);
assign c[6]=(a_i[25]|a_i[24])|(a_i[27]|a_i[26]);
assign c[7]=(a_i[29]|a_i[28])|(a_i[31]|a_i[30]);

wire [7:0] u1 = c  | {1'b0, c[7:1]};
wire [7:0] u2 = u1 | {2'b0, u1[7:2]};
wire [7:0] U  = u2 | {4'b0, u2[7:4]};   // U[j] = |c[7:j] = |a[31:4j]

wire [7:0] e;
assign e[0]=a_i[3]|a_i[2];   assign e[1]=a_i[7]|a_i[6];
assign e[2]=a_i[11]|a_i[10]; assign e[3]=a_i[15]|a_i[14];
assign e[4]=a_i[19]|a_i[18]; assign e[5]=a_i[23]|a_i[22];
assign e[6]=a_i[27]|a_i[26]; assign e[7]=a_i[31]|a_i[30];

wire [7:0] d;
assign d[0]=a_i[3] |(a_i[1] &~a_i[2]);  assign d[1]=a_i[7] |(a_i[5] &~a_i[6]);
assign d[2]=a_i[11]|(a_i[9] &~a_i[10]); assign d[3]=a_i[15]|(a_i[13]&~a_i[14]);
assign d[4]=a_i[19]|(a_i[17]&~a_i[18]); assign d[5]=a_i[23]|(a_i[21]&~a_i[22]);
assign d[6]=a_i[27]|(a_i[25]&~a_i[26]); assign d[7]=a_i[31]|(a_i[29]&~a_i[30]);

wire [5:0] chosen;
assign chosen[5] = U[0];
assign chosen[4] = U[4];
assign chosen[3] = U[6] | (U[2] & ~U[4]);
assign chosen[2] = (U[7] | (U[5] & ~U[6])) | ((U[3] & ~U[4]) | (U[1] & ~U[2]));
assign chosen[1] = ((e[7] | (e[6]&~U[7])) | ((e[5]&~U[6]) | (e[4]&~U[5]))) |
                   (((e[3]&~U[4]) | (e[2]&~U[3])) | ((e[1]&~U[2]) | (e[0]&~U[1])));
assign chosen[0] = ((d[7] | (d[6]&~U[7])) | ((d[5]&~U[6]) | (d[4]&~U[5]))) |
                   (((d[3]&~U[4]) | (d[2]&~U[3])) | ((d[1]&~U[2]) | (d[0]&~U[1])));

wire wen  = rst_n & valid_i;
wire keep = rst_n & ~valid_i;
always @(posedge clk) begin
    valid_o <= wen;
    y_o <= ({6{wen}} & chosen) | ({6{keep}} & y_o);
end
endmodule
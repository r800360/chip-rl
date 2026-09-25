module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// suffix-OR prefix network: m[k] = |a_i[31:k]
wire [31:0] s1 = a_i | {1'b0,  a_i[31:1]};
wire [31:0] s2 = s1  | {2'b0,  s1[31:2]};
wire [31:0] s4 = s2  | {4'b0,  s2[31:4]};
wire [31:0] s8 = s4  | {8'b0,  s4[31:8]};
wire [31:0] m  = s8  | {16'b0, s8[31:16]};

wire [5:0] chosen;
assign chosen[5] = m[0];
assign chosen[4] = m[16];
assign chosen[3] = m[24] | (m[8] & ~m[16]);
assign chosen[2] = m[28] | (m[20] & ~m[24]) | (m[12] & ~m[16]) | (m[4] & ~m[8]);
assign chosen[1] = m[30] | (m[26] & ~m[28]) | (m[22] & ~m[24]) | (m[18] & ~m[20]) |
                   (m[14] & ~m[16]) | (m[10] & ~m[12]) | (m[6] & ~m[8]) | (m[2] & ~m[4]);
assign chosen[0] = m[31] | (m[29] & ~m[30]) | (m[27] & ~m[28]) | (m[25] & ~m[26]) |
                   (m[23] & ~m[24]) | (m[21] & ~m[22]) | (m[19] & ~m[20]) | (m[17] & ~m[18]) |
                   (m[15] & ~m[16]) | (m[13] & ~m[14]) | (m[11] & ~m[12]) | (m[9]  & ~m[10]) |
                   (m[7]  & ~m[8])  | (m[5]  & ~m[6])  | (m[3]  & ~m[4])  | (m[1]  & ~m[2]);

wire wen = rst_n & valid_i;
wire [5:0] y_hold = y_o & {6{rst_n}};

always @(posedge clk) begin
    valid_o <= wen;
    y_o <= wen ? chosen : y_hold;
end
endmodule
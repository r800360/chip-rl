module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [31:0] p16 = a_i | {16'b0, a_i[31:16]};
wire [31:0] p8  = p16 | {8'b0,  p16[31:8]};
wire [31:0] p4  = p8  | {4'b0,  p8[31:4]};
wire [31:0] p2  = p4  | {2'b0,  p4[31:2]};
wire [31:0] m   = p2  | {1'b0,  p2[31:1]};

wire h0a = (m[31] | (m[29] & ~m[30])) | ((m[27] & ~m[28]) | (m[25] & ~m[26]));
wire h0b = ((m[23] & ~m[24]) | (m[21] & ~m[22])) | ((m[19] & ~m[20]) | (m[17] & ~m[18]));
wire h0c = ((m[15] & ~m[16]) | (m[13] & ~m[14])) | ((m[11] & ~m[12]) | (m[9] & ~m[10]));
wire h0d = ((m[7] & ~m[8]) | (m[5] & ~m[6])) | ((m[3] & ~m[4]) | (m[1] & ~m[2]));
wire h1a = (m[30] | (m[26] & ~m[28])) | ((m[22] & ~m[24]) | (m[18] & ~m[20]));
wire h1b = ((m[14] & ~m[16]) | (m[10] & ~m[12])) | ((m[6] & ~m[8]) | (m[2] & ~m[4]));

wire [5:0] chosen;
assign chosen[5] = m[0];
assign chosen[4] = m[16];
assign chosen[3] = m[24] | (m[8] & ~m[16]);
assign chosen[2] = (m[28] | (m[20] & ~m[24])) | ((m[12] & ~m[16]) | (m[4] & ~m[8]));
assign chosen[1] = h1a | h1b;
assign chosen[0] = (h0a | h0b) | (h0c | h0d);

wire wen  = rst_n & valid_i;
wire keep = rst_n & ~valid_i;
always @(posedge clk) begin
    valid_o <= wen;
    y_o <= ({6{wen}} & chosen) | ({6{keep}} & y_o);
end
endmodule
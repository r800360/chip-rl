module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [32:0] m;
assign m[32] = 1'b0;
assign m[31] = a_i[31] | m[32];
assign m[30] = a_i[30] | m[31];
assign m[29] = a_i[29] | m[30];
assign m[28] = a_i[28] | m[29];
assign m[27] = a_i[27] | m[28];
assign m[26] = a_i[26] | m[27];
assign m[25] = a_i[25] | m[26];
assign m[24] = a_i[24] | m[25];
assign m[23] = a_i[23] | m[24];
assign m[22] = a_i[22] | m[23];
assign m[21] = a_i[21] | m[22];
assign m[20] = a_i[20] | m[21];
assign m[19] = a_i[19] | m[20];
assign m[18] = a_i[18] | m[19];
assign m[17] = a_i[17] | m[18];
assign m[16] = a_i[16] | m[17];
assign m[15] = a_i[15] | m[16];
assign m[14] = a_i[14] | m[15];
assign m[13] = a_i[13] | m[14];
assign m[12] = a_i[12] | m[13];
assign m[11] = a_i[11] | m[12];
assign m[10] = a_i[10] | m[11];
assign m[9]  = a_i[9]  | m[10];
assign m[8]  = a_i[8]  | m[9];
assign m[7]  = a_i[7]  | m[8];
assign m[6]  = a_i[6]  | m[7];
assign m[5]  = a_i[5]  | m[6];
assign m[4]  = a_i[4]  | m[5];
assign m[3]  = a_i[3]  | m[4];
assign m[2]  = a_i[2]  | m[3];
assign m[1]  = a_i[1]  | m[2];
assign m[0]  = a_i[0]  | m[1];
wire [31:0] oh = m[31:0] & ~m[32:1];
wire [5:0] chosen_0 = { m[0],
                        |(oh & 32'hFFFF0000),
                        |(oh & 32'hFF00FF00),
                        |(oh & 32'hF0F0F0F0),
                        |(oh & 32'hCCCCCCCC),
                        |(oh & 32'hAAAAAAAA) };
wire en = valid_i & rst_n;
always @(posedge clk) begin
    valid_o <= en;
    y_o <= en ? chosen_0 : (y_o & {6{rst_n}});
end
endmodule
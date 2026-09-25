module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Minimal width tree with careful width management
wire [1:0] s1[0:15];

assign s1[0] = a_i[0] + a_i[1];
assign s1[1] = a_i[2] + a_i[3];
assign s1[2] = a_i[4] + a_i[5];
assign s1[3] = a_i[6] + a_i[7];
assign s1[4] = a_i[8] + a_i[9];
assign s1[5] = a_i[10] + a_i[11];
assign s1[6] = a_i[12] + a_i[13];
assign s1[7] = a_i[14] + a_i[15];
assign s1[8] = a_i[16] + a_i[17];
assign s1[9] = a_i[18] + a_i[19];
assign s1[10] = a_i[20] + a_i[21];
assign s1[11] = a_i[22] + a_i[23];
assign s1[12] = a_i[24] + a_i[25];
assign s1[13] = a_i[26] + a_i[27];
assign s1[14] = a_i[28] + a_i[29];
assign s1[15] = a_i[30] + a_i[31];

wire [2:0] s2[0:7];

assign s2[0] = s1[0] + s1[1];
assign s2[1] = s1[2] + s1[3];
assign s2[2] = s1[4] + s1[5];
assign s2[3] = s1[6] + s1[7];
assign s2[4] = s1[8] + s1[9];
assign s2[5] = s1[10] + s1[11];
assign s2[6] = s1[12] + s1[13];
assign s2[7] = s1[14] + s1[15];

wire [3:0] s3[0:3];

assign s3[0] = s2[0] + s2[1];
assign s3[1] = s2[2] + s2[3];
assign s3[2] = s2[4] + s2[5];
assign s3[3] = s2[6] + s2[7];

wire [4:0] s4[0:1];

assign s4[0] = s3[0] + s3[1];
assign s4[1] = s3[2] + s3[3];

wire [5:0] total_0 = s4[0] + s4[1];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= total_0;
    end
end
endmodule

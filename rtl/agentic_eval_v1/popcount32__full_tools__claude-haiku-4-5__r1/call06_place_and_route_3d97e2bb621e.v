module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire [5:0] sum_l1_0 = a_i[0] + a_i[1] + a_i[2] + a_i[3];
wire [5:0] sum_l1_1 = a_i[4] + a_i[5] + a_i[6] + a_i[7];
wire [5:0] sum_l1_2 = a_i[8] + a_i[9] + a_i[10] + a_i[11];
wire [5:0] sum_l1_3 = a_i[12] + a_i[13] + a_i[14] + a_i[15];
wire [5:0] sum_l1_4 = a_i[16] + a_i[17] + a_i[18] + a_i[19];
wire [5:0] sum_l1_5 = a_i[20] + a_i[21] + a_i[22] + a_i[23];
wire [5:0] sum_l1_6 = a_i[24] + a_i[25] + a_i[26] + a_i[27];
wire [5:0] sum_l1_7 = a_i[28] + a_i[29] + a_i[30] + a_i[31];

wire [5:0] sum_l2_0 = sum_l1_0 + sum_l1_1;
wire [5:0] sum_l2_1 = sum_l1_2 + sum_l1_3;
wire [5:0] sum_l2_2 = sum_l1_4 + sum_l1_5;
wire [5:0] sum_l2_3 = sum_l1_6 + sum_l1_7;

wire [5:0] sum_l3_0 = sum_l2_0 + sum_l2_1;
wire [5:0] sum_l3_1 = sum_l2_2 + sum_l2_3;

wire [5:0] pc_0 = sum_l3_0 + sum_l3_1;

wire [5:0] total_0 = pc_0;

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
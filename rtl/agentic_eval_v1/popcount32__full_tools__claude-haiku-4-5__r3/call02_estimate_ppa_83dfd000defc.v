module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Balanced tree popcount
// Level 1: 16 2-bit sums (pairwise addition of bits)
wire [1:0] l1_0 = a_i[0] + a_i[1];
wire [1:0] l1_1 = a_i[2] + a_i[3];
wire [1:0] l1_2 = a_i[4] + a_i[5];
wire [1:0] l1_3 = a_i[6] + a_i[7];
wire [1:0] l1_4 = a_i[8] + a_i[9];
wire [1:0] l1_5 = a_i[10] + a_i[11];
wire [1:0] l1_6 = a_i[12] + a_i[13];
wire [1:0] l1_7 = a_i[14] + a_i[15];
wire [1:0] l1_8 = a_i[16] + a_i[17];
wire [1:0] l1_9 = a_i[18] + a_i[19];
wire [1:0] l1_10 = a_i[20] + a_i[21];
wire [1:0] l1_11 = a_i[22] + a_i[23];
wire [1:0] l1_12 = a_i[24] + a_i[25];
wire [1:0] l1_13 = a_i[26] + a_i[27];
wire [1:0] l1_14 = a_i[28] + a_i[29];
wire [1:0] l1_15 = a_i[30] + a_i[31];

// Level 2: 8 3-bit sums
wire [2:0] l2_0 = l1_0 + l1_1;
wire [2:0] l2_1 = l1_2 + l1_3;
wire [2:0] l2_2 = l1_4 + l1_5;
wire [2:0] l2_3 = l1_6 + l1_7;
wire [2:0] l2_4 = l1_8 + l1_9;
wire [2:0] l2_5 = l1_10 + l1_11;
wire [2:0] l2_6 = l1_12 + l1_13;
wire [2:0] l2_7 = l1_14 + l1_15;

// Level 3: 4 4-bit sums
wire [3:0] l3_0 = l2_0 + l2_1;
wire [3:0] l3_1 = l2_2 + l2_3;
wire [3:0] l3_2 = l2_4 + l2_5;
wire [3:0] l3_3 = l2_6 + l2_7;

// Level 4: 2 5-bit sums
wire [4:0] l4_0 = l3_0 + l3_1;
wire [4:0] l4_1 = l3_2 + l3_3;

// Final: 6-bit sum
wire [5:0] total_0 = l4_0 + l4_1;

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

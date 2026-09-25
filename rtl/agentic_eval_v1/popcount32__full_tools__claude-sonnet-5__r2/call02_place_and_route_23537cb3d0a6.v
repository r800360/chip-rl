module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Level 1: 16 x 2-bit sums
wire [1:0] s1_0  = a_i[0]  + a_i[1];
wire [1:0] s1_1  = a_i[2]  + a_i[3];
wire [1:0] s1_2  = a_i[4]  + a_i[5];
wire [1:0] s1_3  = a_i[6]  + a_i[7];
wire [1:0] s1_4  = a_i[8]  + a_i[9];
wire [1:0] s1_5  = a_i[10] + a_i[11];
wire [1:0] s1_6  = a_i[12] + a_i[13];
wire [1:0] s1_7  = a_i[14] + a_i[15];
wire [1:0] s1_8  = a_i[16] + a_i[17];
wire [1:0] s1_9  = a_i[18] + a_i[19];
wire [1:0] s1_10 = a_i[20] + a_i[21];
wire [1:0] s1_11 = a_i[22] + a_i[23];
wire [1:0] s1_12 = a_i[24] + a_i[25];
wire [1:0] s1_13 = a_i[26] + a_i[27];
wire [1:0] s1_14 = a_i[28] + a_i[29];
wire [1:0] s1_15 = a_i[30] + a_i[31];

// Level 2: 8 x 3-bit sums
wire [2:0] s2_0 = s1_0  + s1_1;
wire [2:0] s2_1 = s1_2  + s1_3;
wire [2:0] s2_2 = s1_4  + s1_5;
wire [2:0] s2_3 = s1_6  + s1_7;
wire [2:0] s2_4 = s1_8  + s1_9;
wire [2:0] s2_5 = s1_10 + s1_11;
wire [2:0] s2_6 = s1_12 + s1_13;
wire [2:0] s2_7 = s1_14 + s1_15;

// Level 3: 4 x 4-bit sums
wire [3:0] s3_0 = s2_0 + s2_1;
wire [3:0] s3_1 = s2_2 + s2_3;
wire [3:0] s3_2 = s2_4 + s2_5;
wire [3:0] s3_3 = s2_6 + s2_7;

// Level 4: 2 x 5-bit sums
wire [4:0] s4_0 = s3_0 + s3_1;
wire [4:0] s4_1 = s3_2 + s3_3;

// Level 5: 1 x 6-bit sum
wire [5:0] total_0 = s4_0 + s4_1;

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

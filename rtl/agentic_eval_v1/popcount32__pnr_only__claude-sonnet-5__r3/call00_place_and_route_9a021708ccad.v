module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Balanced binary adder tree for population count (32 -> 6 bits)
// Level 1: 16 pairs, 2-bit sums (0..2)
wire [1:0] p1_0  = a_i[0]  + a_i[1];
wire [1:0] p1_1  = a_i[2]  + a_i[3];
wire [1:0] p1_2  = a_i[4]  + a_i[5];
wire [1:0] p1_3  = a_i[6]  + a_i[7];
wire [1:0] p1_4  = a_i[8]  + a_i[9];
wire [1:0] p1_5  = a_i[10] + a_i[11];
wire [1:0] p1_6  = a_i[12] + a_i[13];
wire [1:0] p1_7  = a_i[14] + a_i[15];
wire [1:0] p1_8  = a_i[16] + a_i[17];
wire [1:0] p1_9  = a_i[18] + a_i[19];
wire [1:0] p1_10 = a_i[20] + a_i[21];
wire [1:0] p1_11 = a_i[22] + a_i[23];
wire [1:0] p1_12 = a_i[24] + a_i[25];
wire [1:0] p1_13 = a_i[26] + a_i[27];
wire [1:0] p1_14 = a_i[28] + a_i[29];
wire [1:0] p1_15 = a_i[30] + a_i[31];

// Level 2: 8 sums, 3-bit (0..4)
wire [2:0] p2_0 = p1_0  + p1_1;
wire [2:0] p2_1 = p1_2  + p1_3;
wire [2:0] p2_2 = p1_4  + p1_5;
wire [2:0] p2_3 = p1_6  + p1_7;
wire [2:0] p2_4 = p1_8  + p1_9;
wire [2:0] p2_5 = p1_10 + p1_11;
wire [2:0] p2_6 = p1_12 + p1_13;
wire [2:0] p2_7 = p1_14 + p1_15;

// Level 3: 4 sums, 4-bit (0..8)
wire [3:0] p3_0 = p2_0 + p2_1;
wire [3:0] p3_1 = p2_2 + p2_3;
wire [3:0] p3_2 = p2_4 + p2_5;
wire [3:0] p3_3 = p2_6 + p2_7;

// Level 4: 2 sums, 5-bit (0..16)
wire [4:0] p4_0 = p3_0 + p3_1;
wire [4:0] p4_1 = p3_2 + p3_3;

// Level 5: 1 sum, 6-bit (0..32)
wire [5:0] total_0 = p4_0 + p4_1;

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

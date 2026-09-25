module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Pipelined popcount (2 stages)
// Stage 1 combinational: compute first level
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

// Register stage 1
reg [1:0] s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7;
reg [1:0] s1_8, s1_9, s1_10, s1_11, s1_12, s1_13, s1_14, s1_15;
reg valid_1;

always @(posedge clk) begin
    if (!rst_n) begin
        s1_0 <= 2'b0;
        s1_1 <= 2'b0;
        s1_2 <= 2'b0;
        s1_3 <= 2'b0;
        s1_4 <= 2'b0;
        s1_5 <= 2'b0;
        s1_6 <= 2'b0;
        s1_7 <= 2'b0;
        s1_8 <= 2'b0;
        s1_9 <= 2'b0;
        s1_10 <= 2'b0;
        s1_11 <= 2'b0;
        s1_12 <= 2'b0;
        s1_13 <= 2'b0;
        s1_14 <= 2'b0;
        s1_15 <= 2'b0;
        valid_1 <= 1'b0;
    end else begin
        s1_0 <= l1_0;
        s1_1 <= l1_1;
        s1_2 <= l1_2;
        s1_3 <= l1_3;
        s1_4 <= l1_4;
        s1_5 <= l1_5;
        s1_6 <= l1_6;
        s1_7 <= l1_7;
        s1_8 <= l1_8;
        s1_9 <= l1_9;
        s1_10 <= l1_10;
        s1_11 <= l1_11;
        s1_12 <= l1_12;
        s1_13 <= l1_13;
        s1_14 <= l1_14;
        s1_15 <= l1_15;
        valid_1 <= valid_i;
    end
end

// Stage 2: Combine registered values
wire [2:0] l2_0 = s1_0 + s1_1;
wire [2:0] l2_1 = s1_2 + s1_3;
wire [2:0] l2_2 = s1_4 + s1_5;
wire [2:0] l2_3 = s1_6 + s1_7;
wire [2:0] l2_4 = s1_8 + s1_9;
wire [2:0] l2_5 = s1_10 + s1_11;
wire [2:0] l2_6 = s1_12 + s1_13;
wire [2:0] l2_7 = s1_14 + s1_15;

wire [3:0] l3_0 = l2_0 + l2_1;
wire [3:0] l3_1 = l2_2 + l2_3;
wire [3:0] l3_2 = l2_4 + l2_5;
wire [3:0] l3_3 = l2_6 + l2_7;

wire [4:0] l4_0 = l3_0 + l3_1;
wire [4:0] l4_1 = l3_2 + l3_3;

wire [5:0] total_0 = l4_0 + l4_1;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_1;
        if (valid_1)
            y_o <= total_0;
    end
end
endmodule

module addpipe56 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [55:0] a_i,
    input  wire [55:0] b_i,
    output reg         valid_o,
    output reg  [55:0] y_o
);

wire [2:0] block_0;
wire [1:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[1:0]} +
    {1'b0, b_i[1:0]};

assign sum_0 =
    block_0[1:0];

assign carry_0 =
    block_0[2];

wire [2:0] block_1_0;
wire [2:0] block_1_1;
wire [2:0] block_1;
wire [1:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[3:2]} +
    {1'b0, b_i[3:2]};

assign block_1_1 =
    {1'b0, a_i[3:2]} +
    {1'b0, b_i[3:2]} +
    3'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[1:0];

assign carry_1 =
    block_1[2];

wire [5:0] block_2_0;
wire [5:0] block_2_1;
wire [5:0] block_2;
wire [4:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[8:4]} +
    {1'b0, b_i[8:4]};

assign block_2_1 =
    {1'b0, a_i[8:4]} +
    {1'b0, b_i[8:4]} +
    6'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[4:0];

assign carry_2 =
    block_2[5];

wire [2:0] block_3_0;
wire [2:0] block_3_1;
wire [2:0] block_3;
wire [1:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[10:9]} +
    {1'b0, b_i[10:9]};

assign block_3_1 =
    {1'b0, a_i[10:9]} +
    {1'b0, b_i[10:9]} +
    3'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[1:0];

assign carry_3 =
    block_3[2];

wire [2:0] block_4_0;
wire [2:0] block_4_1;
wire [2:0] block_4;
wire [1:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[12:11]} +
    {1'b0, b_i[12:11]};

assign block_4_1 =
    {1'b0, a_i[12:11]} +
    {1'b0, b_i[12:11]} +
    3'd1;

assign block_4 =
    carry_3
    ? block_4_1
    : block_4_0;

assign sum_4 =
    block_4[1:0];

assign carry_4 =
    block_4[2];

wire [4:0] block_5_0;
wire [4:0] block_5_1;
wire [4:0] block_5;
wire [3:0] sum_5;
wire carry_5;

assign block_5_0 =
    {1'b0, a_i[16:13]} +
    {1'b0, b_i[16:13]};

assign block_5_1 =
    {1'b0, a_i[16:13]} +
    {1'b0, b_i[16:13]} +
    5'd1;

assign block_5 =
    carry_4
    ? block_5_1
    : block_5_0;

assign sum_5 =
    block_5[3:0];

assign carry_5 =
    block_5[4];

wire [5:0] block_6_0;
wire [5:0] block_6_1;
wire [5:0] block_6;
wire [4:0] sum_6;
wire carry_6;

assign block_6_0 =
    {1'b0, a_i[21:17]} +
    {1'b0, b_i[21:17]};

assign block_6_1 =
    {1'b0, a_i[21:17]} +
    {1'b0, b_i[21:17]} +
    6'd1;

assign block_6 =
    carry_5
    ? block_6_1
    : block_6_0;

assign sum_6 =
    block_6[4:0];

assign carry_6 =
    block_6[5];

wire [1:0] block_7_0;
wire [1:0] block_7_1;
wire [1:0] block_7;
wire [0:0] sum_7;
wire carry_7;

assign block_7_0 =
    {1'b0, a_i[22]} +
    {1'b0, b_i[22]};

assign block_7_1 =
    {1'b0, a_i[22]} +
    {1'b0, b_i[22]} +
    2'd1;

assign block_7 =
    carry_6
    ? block_7_1
    : block_7_0;

assign sum_7 =
    block_7[0:0];

assign carry_7 =
    block_7[1];

wire [2:0] block_8_0;
wire [2:0] block_8_1;
wire [2:0] block_8;
wire [1:0] sum_8;
wire carry_8;

assign block_8_0 =
    {1'b0, a_i[24:23]} +
    {1'b0, b_i[24:23]};

assign block_8_1 =
    {1'b0, a_i[24:23]} +
    {1'b0, b_i[24:23]} +
    3'd1;

assign block_8 =
    carry_7
    ? block_8_1
    : block_8_0;

assign sum_8 =
    block_8[1:0];

assign carry_8 =
    block_8[2];

wire [2:0] block_9_0;
wire [2:0] block_9_1;
wire [2:0] block_9;
wire [1:0] sum_9;
wire carry_9;

assign block_9_0 =
    {1'b0, a_i[26:25]} +
    {1'b0, b_i[26:25]};

assign block_9_1 =
    {1'b0, a_i[26:25]} +
    {1'b0, b_i[26:25]} +
    3'd1;

assign block_9 =
    carry_8
    ? block_9_1
    : block_9_0;

assign sum_9 =
    block_9[1:0];

assign carry_9 =
    block_9[2];

wire [2:0] block_10_0;
wire [2:0] block_10_1;
wire [2:0] block_10;
wire [1:0] sum_10;
wire carry_10;

assign block_10_0 =
    {1'b0, a_i[28:27]} +
    {1'b0, b_i[28:27]};

assign block_10_1 =
    {1'b0, a_i[28:27]} +
    {1'b0, b_i[28:27]} +
    3'd1;

assign block_10 =
    carry_9
    ? block_10_1
    : block_10_0;

assign sum_10 =
    block_10[1:0];

assign carry_10 =
    block_10[2];

wire [3:0] block_11_0;
wire [3:0] block_11_1;
wire [3:0] block_11;
wire [2:0] sum_11;
wire carry_11;

assign block_11_0 =
    {1'b0, a_i[31:29]} +
    {1'b0, b_i[31:29]};

assign block_11_1 =
    {1'b0, a_i[31:29]} +
    {1'b0, b_i[31:29]} +
    4'd1;

assign block_11 =
    carry_10
    ? block_11_1
    : block_11_0;

assign sum_11 =
    block_11[2:0];

assign carry_11 =
    block_11[3];

wire [2:0] block_12_0;
wire [2:0] block_12_1;
wire [2:0] block_12;
wire [1:0] sum_12;
wire carry_12;

assign block_12_0 =
    {1'b0, a_i[33:32]} +
    {1'b0, b_i[33:32]};

assign block_12_1 =
    {1'b0, a_i[33:32]} +
    {1'b0, b_i[33:32]} +
    3'd1;

assign block_12 =
    carry_11
    ? block_12_1
    : block_12_0;

assign sum_12 =
    block_12[1:0];

assign carry_12 =
    block_12[2];

wire [3:0] block_13_0;
wire [3:0] block_13_1;
wire [3:0] block_13;
wire [2:0] sum_13;
wire carry_13;

assign block_13_0 =
    {1'b0, a_i[36:34]} +
    {1'b0, b_i[36:34]};

assign block_13_1 =
    {1'b0, a_i[36:34]} +
    {1'b0, b_i[36:34]} +
    4'd1;

assign block_13 =
    carry_12
    ? block_13_1
    : block_13_0;

assign sum_13 =
    block_13[2:0];

assign carry_13 =
    block_13[3];

wire [1:0] block_14_0;
wire [1:0] block_14_1;
wire [1:0] block_14;
wire [0:0] sum_14;
wire carry_14;

assign block_14_0 =
    {1'b0, a_i[37]} +
    {1'b0, b_i[37]};

assign block_14_1 =
    {1'b0, a_i[37]} +
    {1'b0, b_i[37]} +
    2'd1;

assign block_14 =
    carry_13
    ? block_14_1
    : block_14_0;

assign sum_14 =
    block_14[0:0];

assign carry_14 =
    block_14[1];

wire [6:0] block_15_0;
wire [6:0] block_15_1;
wire [6:0] block_15;
wire [5:0] sum_15;
wire carry_15;

assign block_15_0 =
    {1'b0, a_i[43:38]} +
    {1'b0, b_i[43:38]};

assign block_15_1 =
    {1'b0, a_i[43:38]} +
    {1'b0, b_i[43:38]} +
    7'd1;

assign block_15 =
    carry_14
    ? block_15_1
    : block_15_0;

assign sum_15 =
    block_15[5:0];

assign carry_15 =
    block_15[6];

wire [1:0] block_16_0;
wire [1:0] block_16_1;
wire [1:0] block_16;
wire [0:0] sum_16;
wire carry_16;

assign block_16_0 =
    {1'b0, a_i[44]} +
    {1'b0, b_i[44]};

assign block_16_1 =
    {1'b0, a_i[44]} +
    {1'b0, b_i[44]} +
    2'd1;

assign block_16 =
    carry_15
    ? block_16_1
    : block_16_0;

assign sum_16 =
    block_16[0:0];

assign carry_16 =
    block_16[1];

wire [3:0] block_17_0;
wire [3:0] block_17_1;
wire [3:0] block_17;
wire [2:0] sum_17;
wire carry_17;

assign block_17_0 =
    {1'b0, a_i[47:45]} +
    {1'b0, b_i[47:45]};

assign block_17_1 =
    {1'b0, a_i[47:45]} +
    {1'b0, b_i[47:45]} +
    4'd1;

assign block_17 =
    carry_16
    ? block_17_1
    : block_17_0;

assign sum_17 =
    block_17[2:0];

assign carry_17 =
    block_17[3];

wire [3:0] block_18_0;
wire [3:0] block_18_1;
wire [3:0] block_18;
wire [2:0] sum_18;
wire carry_18;

assign block_18_0 =
    {1'b0, a_i[50:48]} +
    {1'b0, b_i[50:48]};

assign block_18_1 =
    {1'b0, a_i[50:48]} +
    {1'b0, b_i[50:48]} +
    4'd1;

assign block_18 =
    carry_17
    ? block_18_1
    : block_18_0;

assign sum_18 =
    block_18[2:0];

assign carry_18 =
    block_18[3];

wire [1:0] block_19_0;
wire [1:0] block_19_1;
wire [1:0] block_19;
wire [0:0] sum_19;
wire carry_19;

assign block_19_0 =
    {1'b0, a_i[51]} +
    {1'b0, b_i[51]};

assign block_19_1 =
    {1'b0, a_i[51]} +
    {1'b0, b_i[51]} +
    2'd1;

assign block_19 =
    carry_18
    ? block_19_1
    : block_19_0;

assign sum_19 =
    block_19[0:0];

assign carry_19 =
    block_19[1];

wire [2:0] block_20_0;
wire [2:0] block_20_1;
wire [2:0] block_20;
wire [1:0] sum_20;
wire carry_20;

assign block_20_0 =
    {1'b0, a_i[53:52]} +
    {1'b0, b_i[53:52]};

assign block_20_1 =
    {1'b0, a_i[53:52]} +
    {1'b0, b_i[53:52]} +
    3'd1;

assign block_20 =
    carry_19
    ? block_20_1
    : block_20_0;

assign sum_20 =
    block_20[1:0];

assign carry_20 =
    block_20[2];

wire [1:0] block_21_0;
wire [1:0] block_21_1;
wire [1:0] block_21;
wire [0:0] sum_21;
wire carry_21;

assign block_21_0 =
    {1'b0, a_i[54]} +
    {1'b0, b_i[54]};

assign block_21_1 =
    {1'b0, a_i[54]} +
    {1'b0, b_i[54]} +
    2'd1;

assign block_21 =
    carry_20
    ? block_21_1
    : block_21_0;

assign sum_21 =
    block_21[0:0];

assign carry_21 =
    block_21[1];

wire [1:0] block_22_0;
wire [1:0] block_22_1;
wire [1:0] block_22;
wire [0:0] sum_22;
wire carry_22;

assign block_22_0 =
    {1'b0, a_i[55]} +
    {1'b0, b_i[55]};

assign block_22_1 =
    {1'b0, a_i[55]} +
    {1'b0, b_i[55]} +
    2'd1;

assign block_22 =
    carry_21
    ? block_22_1
    : block_22_0;

assign sum_22 =
    block_22[0:0];

assign carry_22 =
    block_22[1];

wire [55:0] sum;

assign sum = {
    sum_22,
    sum_21,
    sum_20,
    sum_19,
    sum_18,
    sum_17,
    sum_16,
    sum_15,
    sum_14,
    sum_13,
    sum_12,
    sum_11,
    sum_10,
    sum_9,
    sum_8,
    sum_7,
    sum_6,
    sum_5,
    sum_4,
    sum_3,
    sum_2,
    sum_1,
    sum_0
};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 56'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

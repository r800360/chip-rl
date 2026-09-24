module addpipe48 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [47:0] a_i,
    input  wire [47:0] b_i,
    output reg         valid_o,
    output reg  [47:0] y_o
);

wire [1:0] block_0;
wire [0:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[0]} +
    {1'b0, b_i[0]};

assign sum_0 =
    block_0[0:0];

assign carry_0 =
    block_0[1];

wire [1:0] block_1_0;
wire [1:0] block_1_1;
wire [1:0] block_1;
wire [0:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[1]} +
    {1'b0, b_i[1]};

assign block_1_1 =
    {1'b0, a_i[1]} +
    {1'b0, b_i[1]} +
    2'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[0:0];

assign carry_1 =
    block_1[1];

wire [6:0] block_2_0;
wire [6:0] block_2_1;
wire [6:0] block_2;
wire [5:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[7:2]} +
    {1'b0, b_i[7:2]};

assign block_2_1 =
    {1'b0, a_i[7:2]} +
    {1'b0, b_i[7:2]} +
    7'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[5:0];

assign carry_2 =
    block_2[6];

wire [4:0] block_3_0;
wire [4:0] block_3_1;
wire [4:0] block_3;
wire [3:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[11:8]} +
    {1'b0, b_i[11:8]};

assign block_3_1 =
    {1'b0, a_i[11:8]} +
    {1'b0, b_i[11:8]} +
    5'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[3:0];

assign carry_3 =
    block_3[4];

wire [1:0] block_4_0;
wire [1:0] block_4_1;
wire [1:0] block_4;
wire [0:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[12]} +
    {1'b0, b_i[12]};

assign block_4_1 =
    {1'b0, a_i[12]} +
    {1'b0, b_i[12]} +
    2'd1;

assign block_4 =
    carry_3
    ? block_4_1
    : block_4_0;

assign sum_4 =
    block_4[0:0];

assign carry_4 =
    block_4[1];

wire [1:0] block_5_0;
wire [1:0] block_5_1;
wire [1:0] block_5;
wire [0:0] sum_5;
wire carry_5;

assign block_5_0 =
    {1'b0, a_i[13]} +
    {1'b0, b_i[13]};

assign block_5_1 =
    {1'b0, a_i[13]} +
    {1'b0, b_i[13]} +
    2'd1;

assign block_5 =
    carry_4
    ? block_5_1
    : block_5_0;

assign sum_5 =
    block_5[0:0];

assign carry_5 =
    block_5[1];

wire [5:0] block_6_0;
wire [5:0] block_6_1;
wire [5:0] block_6;
wire [4:0] sum_6;
wire carry_6;

assign block_6_0 =
    {1'b0, a_i[18:14]} +
    {1'b0, b_i[18:14]};

assign block_6_1 =
    {1'b0, a_i[18:14]} +
    {1'b0, b_i[18:14]} +
    6'd1;

assign block_6 =
    carry_5
    ? block_6_1
    : block_6_0;

assign sum_6 =
    block_6[4:0];

assign carry_6 =
    block_6[5];

wire [2:0] block_7_0;
wire [2:0] block_7_1;
wire [2:0] block_7;
wire [1:0] sum_7;
wire carry_7;

assign block_7_0 =
    {1'b0, a_i[20:19]} +
    {1'b0, b_i[20:19]};

assign block_7_1 =
    {1'b0, a_i[20:19]} +
    {1'b0, b_i[20:19]} +
    3'd1;

assign block_7 =
    carry_6
    ? block_7_1
    : block_7_0;

assign sum_7 =
    block_7[1:0];

assign carry_7 =
    block_7[2];

wire [1:0] block_8_0;
wire [1:0] block_8_1;
wire [1:0] block_8;
wire [0:0] sum_8;
wire carry_8;

assign block_8_0 =
    {1'b0, a_i[21]} +
    {1'b0, b_i[21]};

assign block_8_1 =
    {1'b0, a_i[21]} +
    {1'b0, b_i[21]} +
    2'd1;

assign block_8 =
    carry_7
    ? block_8_1
    : block_8_0;

assign sum_8 =
    block_8[0:0];

assign carry_8 =
    block_8[1];

wire [2:0] block_9_0;
wire [2:0] block_9_1;
wire [2:0] block_9;
wire [1:0] sum_9;
wire carry_9;

assign block_9_0 =
    {1'b0, a_i[23:22]} +
    {1'b0, b_i[23:22]};

assign block_9_1 =
    {1'b0, a_i[23:22]} +
    {1'b0, b_i[23:22]} +
    3'd1;

assign block_9 =
    carry_8
    ? block_9_1
    : block_9_0;

assign sum_9 =
    block_9[1:0];

assign carry_9 =
    block_9[2];

wire [1:0] block_10_0;
wire [1:0] block_10_1;
wire [1:0] block_10;
wire [0:0] sum_10;
wire carry_10;

assign block_10_0 =
    {1'b0, a_i[24]} +
    {1'b0, b_i[24]};

assign block_10_1 =
    {1'b0, a_i[24]} +
    {1'b0, b_i[24]} +
    2'd1;

assign block_10 =
    carry_9
    ? block_10_1
    : block_10_0;

assign sum_10 =
    block_10[0:0];

assign carry_10 =
    block_10[1];

wire [1:0] block_11_0;
wire [1:0] block_11_1;
wire [1:0] block_11;
wire [0:0] sum_11;
wire carry_11;

assign block_11_0 =
    {1'b0, a_i[25]} +
    {1'b0, b_i[25]};

assign block_11_1 =
    {1'b0, a_i[25]} +
    {1'b0, b_i[25]} +
    2'd1;

assign block_11 =
    carry_10
    ? block_11_1
    : block_11_0;

assign sum_11 =
    block_11[0:0];

assign carry_11 =
    block_11[1];

wire [1:0] block_12_0;
wire [1:0] block_12_1;
wire [1:0] block_12;
wire [0:0] sum_12;
wire carry_12;

assign block_12_0 =
    {1'b0, a_i[26]} +
    {1'b0, b_i[26]};

assign block_12_1 =
    {1'b0, a_i[26]} +
    {1'b0, b_i[26]} +
    2'd1;

assign block_12 =
    carry_11
    ? block_12_1
    : block_12_0;

assign sum_12 =
    block_12[0:0];

assign carry_12 =
    block_12[1];

wire [2:0] block_13_0;
wire [2:0] block_13_1;
wire [2:0] block_13;
wire [1:0] sum_13;
wire carry_13;

assign block_13_0 =
    {1'b0, a_i[28:27]} +
    {1'b0, b_i[28:27]};

assign block_13_1 =
    {1'b0, a_i[28:27]} +
    {1'b0, b_i[28:27]} +
    3'd1;

assign block_13 =
    carry_12
    ? block_13_1
    : block_13_0;

assign sum_13 =
    block_13[1:0];

assign carry_13 =
    block_13[2];

wire [1:0] block_14_0;
wire [1:0] block_14_1;
wire [1:0] block_14;
wire [0:0] sum_14;
wire carry_14;

assign block_14_0 =
    {1'b0, a_i[29]} +
    {1'b0, b_i[29]};

assign block_14_1 =
    {1'b0, a_i[29]} +
    {1'b0, b_i[29]} +
    2'd1;

assign block_14 =
    carry_13
    ? block_14_1
    : block_14_0;

assign sum_14 =
    block_14[0:0];

assign carry_14 =
    block_14[1];

wire [2:0] block_15_0;
wire [2:0] block_15_1;
wire [2:0] block_15;
wire [1:0] sum_15;
wire carry_15;

assign block_15_0 =
    {1'b0, a_i[31:30]} +
    {1'b0, b_i[31:30]};

assign block_15_1 =
    {1'b0, a_i[31:30]} +
    {1'b0, b_i[31:30]} +
    3'd1;

assign block_15 =
    carry_14
    ? block_15_1
    : block_15_0;

assign sum_15 =
    block_15[1:0];

assign carry_15 =
    block_15[2];

wire [1:0] block_16_0;
wire [1:0] block_16_1;
wire [1:0] block_16;
wire [0:0] sum_16;
wire carry_16;

assign block_16_0 =
    {1'b0, a_i[32]} +
    {1'b0, b_i[32]};

assign block_16_1 =
    {1'b0, a_i[32]} +
    {1'b0, b_i[32]} +
    2'd1;

assign block_16 =
    carry_15
    ? block_16_1
    : block_16_0;

assign sum_16 =
    block_16[0:0];

assign carry_16 =
    block_16[1];

wire [4:0] block_17_0;
wire [4:0] block_17_1;
wire [4:0] block_17;
wire [3:0] sum_17;
wire carry_17;

assign block_17_0 =
    {1'b0, a_i[36:33]} +
    {1'b0, b_i[36:33]};

assign block_17_1 =
    {1'b0, a_i[36:33]} +
    {1'b0, b_i[36:33]} +
    5'd1;

assign block_17 =
    carry_16
    ? block_17_1
    : block_17_0;

assign sum_17 =
    block_17[3:0];

assign carry_17 =
    block_17[4];

wire [2:0] block_18_0;
wire [2:0] block_18_1;
wire [2:0] block_18;
wire [1:0] sum_18;
wire carry_18;

assign block_18_0 =
    {1'b0, a_i[38:37]} +
    {1'b0, b_i[38:37]};

assign block_18_1 =
    {1'b0, a_i[38:37]} +
    {1'b0, b_i[38:37]} +
    3'd1;

assign block_18 =
    carry_17
    ? block_18_1
    : block_18_0;

assign sum_18 =
    block_18[1:0];

assign carry_18 =
    block_18[2];

wire [5:0] block_19_0;
wire [5:0] block_19_1;
wire [5:0] block_19;
wire [4:0] sum_19;
wire carry_19;

assign block_19_0 =
    {1'b0, a_i[43:39]} +
    {1'b0, b_i[43:39]};

assign block_19_1 =
    {1'b0, a_i[43:39]} +
    {1'b0, b_i[43:39]} +
    6'd1;

assign block_19 =
    carry_18
    ? block_19_1
    : block_19_0;

assign sum_19 =
    block_19[4:0];

assign carry_19 =
    block_19[5];

wire [2:0] block_20_0;
wire [2:0] block_20_1;
wire [2:0] block_20;
wire [1:0] sum_20;
wire carry_20;

assign block_20_0 =
    {1'b0, a_i[45:44]} +
    {1'b0, b_i[45:44]};

assign block_20_1 =
    {1'b0, a_i[45:44]} +
    {1'b0, b_i[45:44]} +
    3'd1;

assign block_20 =
    carry_19
    ? block_20_1
    : block_20_0;

assign sum_20 =
    block_20[1:0];

assign carry_20 =
    block_20[2];

wire [2:0] block_21_0;
wire [2:0] block_21_1;
wire [2:0] block_21;
wire [1:0] sum_21;
wire carry_21;

assign block_21_0 =
    {1'b0, a_i[47:46]} +
    {1'b0, b_i[47:46]};

assign block_21_1 =
    {1'b0, a_i[47:46]} +
    {1'b0, b_i[47:46]} +
    3'd1;

assign block_21 =
    carry_20
    ? block_21_1
    : block_21_0;

assign sum_21 =
    block_21[1:0];

assign carry_21 =
    block_21[2];

wire [47:0] sum;

assign sum = {
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
        y_o     <= 48'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

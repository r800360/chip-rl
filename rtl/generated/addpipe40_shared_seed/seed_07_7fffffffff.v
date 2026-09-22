module addpipe40 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [39:0] a_i,
    input  wire [39:0] b_i,
    output reg         valid_o,
    output reg  [39:0] y_o
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

wire [1:0] block_2_0;
wire [1:0] block_2_1;
wire [1:0] block_2;
wire [0:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[2]} +
    {1'b0, b_i[2]};

assign block_2_1 =
    {1'b0, a_i[2]} +
    {1'b0, b_i[2]} +
    2'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[0:0];

assign carry_2 =
    block_2[1];

wire [1:0] block_3_0;
wire [1:0] block_3_1;
wire [1:0] block_3;
wire [0:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[3]} +
    {1'b0, b_i[3]};

assign block_3_1 =
    {1'b0, a_i[3]} +
    {1'b0, b_i[3]} +
    2'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[0:0];

assign carry_3 =
    block_3[1];

wire [1:0] block_4_0;
wire [1:0] block_4_1;
wire [1:0] block_4;
wire [0:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[4]} +
    {1'b0, b_i[4]};

assign block_4_1 =
    {1'b0, a_i[4]} +
    {1'b0, b_i[4]} +
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
    {1'b0, a_i[5]} +
    {1'b0, b_i[5]};

assign block_5_1 =
    {1'b0, a_i[5]} +
    {1'b0, b_i[5]} +
    2'd1;

assign block_5 =
    carry_4
    ? block_5_1
    : block_5_0;

assign sum_5 =
    block_5[0:0];

assign carry_5 =
    block_5[1];

wire [1:0] block_6_0;
wire [1:0] block_6_1;
wire [1:0] block_6;
wire [0:0] sum_6;
wire carry_6;

assign block_6_0 =
    {1'b0, a_i[6]} +
    {1'b0, b_i[6]};

assign block_6_1 =
    {1'b0, a_i[6]} +
    {1'b0, b_i[6]} +
    2'd1;

assign block_6 =
    carry_5
    ? block_6_1
    : block_6_0;

assign sum_6 =
    block_6[0:0];

assign carry_6 =
    block_6[1];

wire [1:0] block_7_0;
wire [1:0] block_7_1;
wire [1:0] block_7;
wire [0:0] sum_7;
wire carry_7;

assign block_7_0 =
    {1'b0, a_i[7]} +
    {1'b0, b_i[7]};

assign block_7_1 =
    {1'b0, a_i[7]} +
    {1'b0, b_i[7]} +
    2'd1;

assign block_7 =
    carry_6
    ? block_7_1
    : block_7_0;

assign sum_7 =
    block_7[0:0];

assign carry_7 =
    block_7[1];

wire [1:0] block_8_0;
wire [1:0] block_8_1;
wire [1:0] block_8;
wire [0:0] sum_8;
wire carry_8;

assign block_8_0 =
    {1'b0, a_i[8]} +
    {1'b0, b_i[8]};

assign block_8_1 =
    {1'b0, a_i[8]} +
    {1'b0, b_i[8]} +
    2'd1;

assign block_8 =
    carry_7
    ? block_8_1
    : block_8_0;

assign sum_8 =
    block_8[0:0];

assign carry_8 =
    block_8[1];

wire [1:0] block_9_0;
wire [1:0] block_9_1;
wire [1:0] block_9;
wire [0:0] sum_9;
wire carry_9;

assign block_9_0 =
    {1'b0, a_i[9]} +
    {1'b0, b_i[9]};

assign block_9_1 =
    {1'b0, a_i[9]} +
    {1'b0, b_i[9]} +
    2'd1;

assign block_9 =
    carry_8
    ? block_9_1
    : block_9_0;

assign sum_9 =
    block_9[0:0];

assign carry_9 =
    block_9[1];

wire [1:0] block_10_0;
wire [1:0] block_10_1;
wire [1:0] block_10;
wire [0:0] sum_10;
wire carry_10;

assign block_10_0 =
    {1'b0, a_i[10]} +
    {1'b0, b_i[10]};

assign block_10_1 =
    {1'b0, a_i[10]} +
    {1'b0, b_i[10]} +
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
    {1'b0, a_i[11]} +
    {1'b0, b_i[11]};

assign block_11_1 =
    {1'b0, a_i[11]} +
    {1'b0, b_i[11]} +
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
    {1'b0, a_i[12]} +
    {1'b0, b_i[12]};

assign block_12_1 =
    {1'b0, a_i[12]} +
    {1'b0, b_i[12]} +
    2'd1;

assign block_12 =
    carry_11
    ? block_12_1
    : block_12_0;

assign sum_12 =
    block_12[0:0];

assign carry_12 =
    block_12[1];

wire [1:0] block_13_0;
wire [1:0] block_13_1;
wire [1:0] block_13;
wire [0:0] sum_13;
wire carry_13;

assign block_13_0 =
    {1'b0, a_i[13]} +
    {1'b0, b_i[13]};

assign block_13_1 =
    {1'b0, a_i[13]} +
    {1'b0, b_i[13]} +
    2'd1;

assign block_13 =
    carry_12
    ? block_13_1
    : block_13_0;

assign sum_13 =
    block_13[0:0];

assign carry_13 =
    block_13[1];

wire [1:0] block_14_0;
wire [1:0] block_14_1;
wire [1:0] block_14;
wire [0:0] sum_14;
wire carry_14;

assign block_14_0 =
    {1'b0, a_i[14]} +
    {1'b0, b_i[14]};

assign block_14_1 =
    {1'b0, a_i[14]} +
    {1'b0, b_i[14]} +
    2'd1;

assign block_14 =
    carry_13
    ? block_14_1
    : block_14_0;

assign sum_14 =
    block_14[0:0];

assign carry_14 =
    block_14[1];

wire [1:0] block_15_0;
wire [1:0] block_15_1;
wire [1:0] block_15;
wire [0:0] sum_15;
wire carry_15;

assign block_15_0 =
    {1'b0, a_i[15]} +
    {1'b0, b_i[15]};

assign block_15_1 =
    {1'b0, a_i[15]} +
    {1'b0, b_i[15]} +
    2'd1;

assign block_15 =
    carry_14
    ? block_15_1
    : block_15_0;

assign sum_15 =
    block_15[0:0];

assign carry_15 =
    block_15[1];

wire [1:0] block_16_0;
wire [1:0] block_16_1;
wire [1:0] block_16;
wire [0:0] sum_16;
wire carry_16;

assign block_16_0 =
    {1'b0, a_i[16]} +
    {1'b0, b_i[16]};

assign block_16_1 =
    {1'b0, a_i[16]} +
    {1'b0, b_i[16]} +
    2'd1;

assign block_16 =
    carry_15
    ? block_16_1
    : block_16_0;

assign sum_16 =
    block_16[0:0];

assign carry_16 =
    block_16[1];

wire [1:0] block_17_0;
wire [1:0] block_17_1;
wire [1:0] block_17;
wire [0:0] sum_17;
wire carry_17;

assign block_17_0 =
    {1'b0, a_i[17]} +
    {1'b0, b_i[17]};

assign block_17_1 =
    {1'b0, a_i[17]} +
    {1'b0, b_i[17]} +
    2'd1;

assign block_17 =
    carry_16
    ? block_17_1
    : block_17_0;

assign sum_17 =
    block_17[0:0];

assign carry_17 =
    block_17[1];

wire [1:0] block_18_0;
wire [1:0] block_18_1;
wire [1:0] block_18;
wire [0:0] sum_18;
wire carry_18;

assign block_18_0 =
    {1'b0, a_i[18]} +
    {1'b0, b_i[18]};

assign block_18_1 =
    {1'b0, a_i[18]} +
    {1'b0, b_i[18]} +
    2'd1;

assign block_18 =
    carry_17
    ? block_18_1
    : block_18_0;

assign sum_18 =
    block_18[0:0];

assign carry_18 =
    block_18[1];

wire [1:0] block_19_0;
wire [1:0] block_19_1;
wire [1:0] block_19;
wire [0:0] sum_19;
wire carry_19;

assign block_19_0 =
    {1'b0, a_i[19]} +
    {1'b0, b_i[19]};

assign block_19_1 =
    {1'b0, a_i[19]} +
    {1'b0, b_i[19]} +
    2'd1;

assign block_19 =
    carry_18
    ? block_19_1
    : block_19_0;

assign sum_19 =
    block_19[0:0];

assign carry_19 =
    block_19[1];

wire [1:0] block_20_0;
wire [1:0] block_20_1;
wire [1:0] block_20;
wire [0:0] sum_20;
wire carry_20;

assign block_20_0 =
    {1'b0, a_i[20]} +
    {1'b0, b_i[20]};

assign block_20_1 =
    {1'b0, a_i[20]} +
    {1'b0, b_i[20]} +
    2'd1;

assign block_20 =
    carry_19
    ? block_20_1
    : block_20_0;

assign sum_20 =
    block_20[0:0];

assign carry_20 =
    block_20[1];

wire [1:0] block_21_0;
wire [1:0] block_21_1;
wire [1:0] block_21;
wire [0:0] sum_21;
wire carry_21;

assign block_21_0 =
    {1'b0, a_i[21]} +
    {1'b0, b_i[21]};

assign block_21_1 =
    {1'b0, a_i[21]} +
    {1'b0, b_i[21]} +
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
    {1'b0, a_i[22]} +
    {1'b0, b_i[22]};

assign block_22_1 =
    {1'b0, a_i[22]} +
    {1'b0, b_i[22]} +
    2'd1;

assign block_22 =
    carry_21
    ? block_22_1
    : block_22_0;

assign sum_22 =
    block_22[0:0];

assign carry_22 =
    block_22[1];

wire [1:0] block_23_0;
wire [1:0] block_23_1;
wire [1:0] block_23;
wire [0:0] sum_23;
wire carry_23;

assign block_23_0 =
    {1'b0, a_i[23]} +
    {1'b0, b_i[23]};

assign block_23_1 =
    {1'b0, a_i[23]} +
    {1'b0, b_i[23]} +
    2'd1;

assign block_23 =
    carry_22
    ? block_23_1
    : block_23_0;

assign sum_23 =
    block_23[0:0];

assign carry_23 =
    block_23[1];

wire [1:0] block_24_0;
wire [1:0] block_24_1;
wire [1:0] block_24;
wire [0:0] sum_24;
wire carry_24;

assign block_24_0 =
    {1'b0, a_i[24]} +
    {1'b0, b_i[24]};

assign block_24_1 =
    {1'b0, a_i[24]} +
    {1'b0, b_i[24]} +
    2'd1;

assign block_24 =
    carry_23
    ? block_24_1
    : block_24_0;

assign sum_24 =
    block_24[0:0];

assign carry_24 =
    block_24[1];

wire [1:0] block_25_0;
wire [1:0] block_25_1;
wire [1:0] block_25;
wire [0:0] sum_25;
wire carry_25;

assign block_25_0 =
    {1'b0, a_i[25]} +
    {1'b0, b_i[25]};

assign block_25_1 =
    {1'b0, a_i[25]} +
    {1'b0, b_i[25]} +
    2'd1;

assign block_25 =
    carry_24
    ? block_25_1
    : block_25_0;

assign sum_25 =
    block_25[0:0];

assign carry_25 =
    block_25[1];

wire [1:0] block_26_0;
wire [1:0] block_26_1;
wire [1:0] block_26;
wire [0:0] sum_26;
wire carry_26;

assign block_26_0 =
    {1'b0, a_i[26]} +
    {1'b0, b_i[26]};

assign block_26_1 =
    {1'b0, a_i[26]} +
    {1'b0, b_i[26]} +
    2'd1;

assign block_26 =
    carry_25
    ? block_26_1
    : block_26_0;

assign sum_26 =
    block_26[0:0];

assign carry_26 =
    block_26[1];

wire [1:0] block_27_0;
wire [1:0] block_27_1;
wire [1:0] block_27;
wire [0:0] sum_27;
wire carry_27;

assign block_27_0 =
    {1'b0, a_i[27]} +
    {1'b0, b_i[27]};

assign block_27_1 =
    {1'b0, a_i[27]} +
    {1'b0, b_i[27]} +
    2'd1;

assign block_27 =
    carry_26
    ? block_27_1
    : block_27_0;

assign sum_27 =
    block_27[0:0];

assign carry_27 =
    block_27[1];

wire [1:0] block_28_0;
wire [1:0] block_28_1;
wire [1:0] block_28;
wire [0:0] sum_28;
wire carry_28;

assign block_28_0 =
    {1'b0, a_i[28]} +
    {1'b0, b_i[28]};

assign block_28_1 =
    {1'b0, a_i[28]} +
    {1'b0, b_i[28]} +
    2'd1;

assign block_28 =
    carry_27
    ? block_28_1
    : block_28_0;

assign sum_28 =
    block_28[0:0];

assign carry_28 =
    block_28[1];

wire [1:0] block_29_0;
wire [1:0] block_29_1;
wire [1:0] block_29;
wire [0:0] sum_29;
wire carry_29;

assign block_29_0 =
    {1'b0, a_i[29]} +
    {1'b0, b_i[29]};

assign block_29_1 =
    {1'b0, a_i[29]} +
    {1'b0, b_i[29]} +
    2'd1;

assign block_29 =
    carry_28
    ? block_29_1
    : block_29_0;

assign sum_29 =
    block_29[0:0];

assign carry_29 =
    block_29[1];

wire [1:0] block_30_0;
wire [1:0] block_30_1;
wire [1:0] block_30;
wire [0:0] sum_30;
wire carry_30;

assign block_30_0 =
    {1'b0, a_i[30]} +
    {1'b0, b_i[30]};

assign block_30_1 =
    {1'b0, a_i[30]} +
    {1'b0, b_i[30]} +
    2'd1;

assign block_30 =
    carry_29
    ? block_30_1
    : block_30_0;

assign sum_30 =
    block_30[0:0];

assign carry_30 =
    block_30[1];

wire [1:0] block_31_0;
wire [1:0] block_31_1;
wire [1:0] block_31;
wire [0:0] sum_31;
wire carry_31;

assign block_31_0 =
    {1'b0, a_i[31]} +
    {1'b0, b_i[31]};

assign block_31_1 =
    {1'b0, a_i[31]} +
    {1'b0, b_i[31]} +
    2'd1;

assign block_31 =
    carry_30
    ? block_31_1
    : block_31_0;

assign sum_31 =
    block_31[0:0];

assign carry_31 =
    block_31[1];

wire [1:0] block_32_0;
wire [1:0] block_32_1;
wire [1:0] block_32;
wire [0:0] sum_32;
wire carry_32;

assign block_32_0 =
    {1'b0, a_i[32]} +
    {1'b0, b_i[32]};

assign block_32_1 =
    {1'b0, a_i[32]} +
    {1'b0, b_i[32]} +
    2'd1;

assign block_32 =
    carry_31
    ? block_32_1
    : block_32_0;

assign sum_32 =
    block_32[0:0];

assign carry_32 =
    block_32[1];

wire [1:0] block_33_0;
wire [1:0] block_33_1;
wire [1:0] block_33;
wire [0:0] sum_33;
wire carry_33;

assign block_33_0 =
    {1'b0, a_i[33]} +
    {1'b0, b_i[33]};

assign block_33_1 =
    {1'b0, a_i[33]} +
    {1'b0, b_i[33]} +
    2'd1;

assign block_33 =
    carry_32
    ? block_33_1
    : block_33_0;

assign sum_33 =
    block_33[0:0];

assign carry_33 =
    block_33[1];

wire [1:0] block_34_0;
wire [1:0] block_34_1;
wire [1:0] block_34;
wire [0:0] sum_34;
wire carry_34;

assign block_34_0 =
    {1'b0, a_i[34]} +
    {1'b0, b_i[34]};

assign block_34_1 =
    {1'b0, a_i[34]} +
    {1'b0, b_i[34]} +
    2'd1;

assign block_34 =
    carry_33
    ? block_34_1
    : block_34_0;

assign sum_34 =
    block_34[0:0];

assign carry_34 =
    block_34[1];

wire [1:0] block_35_0;
wire [1:0] block_35_1;
wire [1:0] block_35;
wire [0:0] sum_35;
wire carry_35;

assign block_35_0 =
    {1'b0, a_i[35]} +
    {1'b0, b_i[35]};

assign block_35_1 =
    {1'b0, a_i[35]} +
    {1'b0, b_i[35]} +
    2'd1;

assign block_35 =
    carry_34
    ? block_35_1
    : block_35_0;

assign sum_35 =
    block_35[0:0];

assign carry_35 =
    block_35[1];

wire [1:0] block_36_0;
wire [1:0] block_36_1;
wire [1:0] block_36;
wire [0:0] sum_36;
wire carry_36;

assign block_36_0 =
    {1'b0, a_i[36]} +
    {1'b0, b_i[36]};

assign block_36_1 =
    {1'b0, a_i[36]} +
    {1'b0, b_i[36]} +
    2'd1;

assign block_36 =
    carry_35
    ? block_36_1
    : block_36_0;

assign sum_36 =
    block_36[0:0];

assign carry_36 =
    block_36[1];

wire [1:0] block_37_0;
wire [1:0] block_37_1;
wire [1:0] block_37;
wire [0:0] sum_37;
wire carry_37;

assign block_37_0 =
    {1'b0, a_i[37]} +
    {1'b0, b_i[37]};

assign block_37_1 =
    {1'b0, a_i[37]} +
    {1'b0, b_i[37]} +
    2'd1;

assign block_37 =
    carry_36
    ? block_37_1
    : block_37_0;

assign sum_37 =
    block_37[0:0];

assign carry_37 =
    block_37[1];

wire [1:0] block_38_0;
wire [1:0] block_38_1;
wire [1:0] block_38;
wire [0:0] sum_38;
wire carry_38;

assign block_38_0 =
    {1'b0, a_i[38]} +
    {1'b0, b_i[38]};

assign block_38_1 =
    {1'b0, a_i[38]} +
    {1'b0, b_i[38]} +
    2'd1;

assign block_38 =
    carry_37
    ? block_38_1
    : block_38_0;

assign sum_38 =
    block_38[0:0];

assign carry_38 =
    block_38[1];

wire [1:0] block_39_0;
wire [1:0] block_39_1;
wire [1:0] block_39;
wire [0:0] sum_39;
wire carry_39;

assign block_39_0 =
    {1'b0, a_i[39]} +
    {1'b0, b_i[39]};

assign block_39_1 =
    {1'b0, a_i[39]} +
    {1'b0, b_i[39]} +
    2'd1;

assign block_39 =
    carry_38
    ? block_39_1
    : block_39_0;

assign sum_39 =
    block_39[0:0];

assign carry_39 =
    block_39[1];

wire [39:0] sum;

assign sum = {
    sum_39,
    sum_38,
    sum_37,
    sum_36,
    sum_35,
    sum_34,
    sum_33,
    sum_32,
    sum_31,
    sum_30,
    sum_29,
    sum_28,
    sum_27,
    sum_26,
    sum_25,
    sum_24,
    sum_23,
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
        y_o     <= 40'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

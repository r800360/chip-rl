module addpipe48 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [47:0] a_i,
    input  wire [47:0] b_i,
    output reg         valid_o,
    output reg  [47:0] y_o
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

wire [1:0] block_2_0;
wire [1:0] block_2_1;
wire [1:0] block_2;
wire [0:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[4]} +
    {1'b0, b_i[4]};

assign block_2_1 =
    {1'b0, a_i[4]} +
    {1'b0, b_i[4]} +
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
    {1'b0, a_i[5]} +
    {1'b0, b_i[5]};

assign block_3_1 =
    {1'b0, a_i[5]} +
    {1'b0, b_i[5]} +
    2'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[0:0];

assign carry_3 =
    block_3[1];

wire [3:0] block_4_0;
wire [3:0] block_4_1;
wire [3:0] block_4;
wire [2:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[8:6]} +
    {1'b0, b_i[8:6]};

assign block_4_1 =
    {1'b0, a_i[8:6]} +
    {1'b0, b_i[8:6]} +
    4'd1;

assign block_4 =
    carry_3
    ? block_4_1
    : block_4_0;

assign sum_4 =
    block_4[2:0];

assign carry_4 =
    block_4[3];

wire [4:0] block_5_0;
wire [4:0] block_5_1;
wire [4:0] block_5;
wire [3:0] sum_5;
wire carry_5;

assign block_5_0 =
    {1'b0, a_i[12:9]} +
    {1'b0, b_i[12:9]};

assign block_5_1 =
    {1'b0, a_i[12:9]} +
    {1'b0, b_i[12:9]} +
    5'd1;

assign block_5 =
    carry_4
    ? block_5_1
    : block_5_0;

assign sum_5 =
    block_5[3:0];

assign carry_5 =
    block_5[4];

wire [4:0] block_6_0;
wire [4:0] block_6_1;
wire [4:0] block_6;
wire [3:0] sum_6;
wire carry_6;

assign block_6_0 =
    {1'b0, a_i[16:13]} +
    {1'b0, b_i[16:13]};

assign block_6_1 =
    {1'b0, a_i[16:13]} +
    {1'b0, b_i[16:13]} +
    5'd1;

assign block_6 =
    carry_5
    ? block_6_1
    : block_6_0;

assign sum_6 =
    block_6[3:0];

assign carry_6 =
    block_6[4];

wire [2:0] block_7_0;
wire [2:0] block_7_1;
wire [2:0] block_7;
wire [1:0] sum_7;
wire carry_7;

assign block_7_0 =
    {1'b0, a_i[18:17]} +
    {1'b0, b_i[18:17]};

assign block_7_1 =
    {1'b0, a_i[18:17]} +
    {1'b0, b_i[18:17]} +
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
    {1'b0, a_i[19]} +
    {1'b0, b_i[19]};

assign block_8_1 =
    {1'b0, a_i[19]} +
    {1'b0, b_i[19]} +
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
    {1'b0, a_i[20]} +
    {1'b0, b_i[20]};

assign block_9_1 =
    {1'b0, a_i[20]} +
    {1'b0, b_i[20]} +
    2'd1;

assign block_9 =
    carry_8
    ? block_9_1
    : block_9_0;

assign sum_9 =
    block_9[0:0];

assign carry_9 =
    block_9[1];

wire [9:0] block_10_0;
wire [9:0] block_10_1;
wire [9:0] block_10;
wire [8:0] sum_10;
wire carry_10;

assign block_10_0 =
    {1'b0, a_i[29:21]} +
    {1'b0, b_i[29:21]};

assign block_10_1 =
    {1'b0, a_i[29:21]} +
    {1'b0, b_i[29:21]} +
    10'd1;

assign block_10 =
    carry_9
    ? block_10_1
    : block_10_0;

assign sum_10 =
    block_10[8:0];

assign carry_10 =
    block_10[9];

wire [5:0] block_11_0;
wire [5:0] block_11_1;
wire [5:0] block_11;
wire [4:0] sum_11;
wire carry_11;

assign block_11_0 =
    {1'b0, a_i[34:30]} +
    {1'b0, b_i[34:30]};

assign block_11_1 =
    {1'b0, a_i[34:30]} +
    {1'b0, b_i[34:30]} +
    6'd1;

assign block_11 =
    carry_10
    ? block_11_1
    : block_11_0;

assign sum_11 =
    block_11[4:0];

assign carry_11 =
    block_11[5];

wire [2:0] block_12_0;
wire [2:0] block_12_1;
wire [2:0] block_12;
wire [1:0] sum_12;
wire carry_12;

assign block_12_0 =
    {1'b0, a_i[36:35]} +
    {1'b0, b_i[36:35]};

assign block_12_1 =
    {1'b0, a_i[36:35]} +
    {1'b0, b_i[36:35]} +
    3'd1;

assign block_12 =
    carry_11
    ? block_12_1
    : block_12_0;

assign sum_12 =
    block_12[1:0];

assign carry_12 =
    block_12[2];

wire [1:0] block_13_0;
wire [1:0] block_13_1;
wire [1:0] block_13;
wire [0:0] sum_13;
wire carry_13;

assign block_13_0 =
    {1'b0, a_i[37]} +
    {1'b0, b_i[37]};

assign block_13_1 =
    {1'b0, a_i[37]} +
    {1'b0, b_i[37]} +
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
    {1'b0, a_i[38]} +
    {1'b0, b_i[38]};

assign block_14_1 =
    {1'b0, a_i[38]} +
    {1'b0, b_i[38]} +
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
    {1'b0, a_i[39]} +
    {1'b0, b_i[39]};

assign block_15_1 =
    {1'b0, a_i[39]} +
    {1'b0, b_i[39]} +
    2'd1;

assign block_15 =
    carry_14
    ? block_15_1
    : block_15_0;

assign sum_15 =
    block_15[0:0];

assign carry_15 =
    block_15[1];

wire [4:0] block_16_0;
wire [4:0] block_16_1;
wire [4:0] block_16;
wire [3:0] sum_16;
wire carry_16;

assign block_16_0 =
    {1'b0, a_i[43:40]} +
    {1'b0, b_i[43:40]};

assign block_16_1 =
    {1'b0, a_i[43:40]} +
    {1'b0, b_i[43:40]} +
    5'd1;

assign block_16 =
    carry_15
    ? block_16_1
    : block_16_0;

assign sum_16 =
    block_16[3:0];

assign carry_16 =
    block_16[4];

wire [4:0] block_17_0;
wire [4:0] block_17_1;
wire [4:0] block_17;
wire [3:0] sum_17;
wire carry_17;

assign block_17_0 =
    {1'b0, a_i[47:44]} +
    {1'b0, b_i[47:44]};

assign block_17_1 =
    {1'b0, a_i[47:44]} +
    {1'b0, b_i[47:44]} +
    5'd1;

assign block_17 =
    carry_16
    ? block_17_1
    : block_17_0;

assign sum_17 =
    block_17[3:0];

assign carry_17 =
    block_17[4];

wire [47:0] sum;

assign sum = {
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

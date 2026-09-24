module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
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

wire [2:0] block_1_0;
wire [2:0] block_1_1;
wire [2:0] block_1;
wire [1:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[2:1]} +
    {1'b0, b_i[2:1]};

assign block_1_1 =
    {1'b0, a_i[2:1]} +
    {1'b0, b_i[2:1]} +
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
    {1'b0, a_i[3]} +
    {1'b0, b_i[3]};

assign block_2_1 =
    {1'b0, a_i[3]} +
    {1'b0, b_i[3]} +
    2'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[0:0];

assign carry_2 =
    block_2[1];

wire [2:0] block_3_0;
wire [2:0] block_3_1;
wire [2:0] block_3;
wire [1:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[5:4]} +
    {1'b0, b_i[5:4]};

assign block_3_1 =
    {1'b0, a_i[5:4]} +
    {1'b0, b_i[5:4]} +
    3'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[1:0];

assign carry_3 =
    block_3[2];

wire [1:0] block_4_0;
wire [1:0] block_4_1;
wire [1:0] block_4;
wire [0:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[6]} +
    {1'b0, b_i[6]};

assign block_4_1 =
    {1'b0, a_i[6]} +
    {1'b0, b_i[6]} +
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
    {1'b0, a_i[7]} +
    {1'b0, b_i[7]};

assign block_5_1 =
    {1'b0, a_i[7]} +
    {1'b0, b_i[7]} +
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
    {1'b0, a_i[8]} +
    {1'b0, b_i[8]};

assign block_6_1 =
    {1'b0, a_i[8]} +
    {1'b0, b_i[8]} +
    2'd1;

assign block_6 =
    carry_5
    ? block_6_1
    : block_6_0;

assign sum_6 =
    block_6[0:0];

assign carry_6 =
    block_6[1];

wire [2:0] block_7_0;
wire [2:0] block_7_1;
wire [2:0] block_7;
wire [1:0] sum_7;
wire carry_7;

assign block_7_0 =
    {1'b0, a_i[10:9]} +
    {1'b0, b_i[10:9]};

assign block_7_1 =
    {1'b0, a_i[10:9]} +
    {1'b0, b_i[10:9]} +
    3'd1;

assign block_7 =
    carry_6
    ? block_7_1
    : block_7_0;

assign sum_7 =
    block_7[1:0];

assign carry_7 =
    block_7[2];

wire [2:0] block_8_0;
wire [2:0] block_8_1;
wire [2:0] block_8;
wire [1:0] sum_8;
wire carry_8;

assign block_8_0 =
    {1'b0, a_i[12:11]} +
    {1'b0, b_i[12:11]};

assign block_8_1 =
    {1'b0, a_i[12:11]} +
    {1'b0, b_i[12:11]} +
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
    {1'b0, a_i[14:13]} +
    {1'b0, b_i[14:13]};

assign block_9_1 =
    {1'b0, a_i[14:13]} +
    {1'b0, b_i[14:13]} +
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
    {1'b0, a_i[15]} +
    {1'b0, b_i[15]};

assign block_10_1 =
    {1'b0, a_i[15]} +
    {1'b0, b_i[15]} +
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
    {1'b0, a_i[16]} +
    {1'b0, b_i[16]};

assign block_11_1 =
    {1'b0, a_i[16]} +
    {1'b0, b_i[16]} +
    2'd1;

assign block_11 =
    carry_10
    ? block_11_1
    : block_11_0;

assign sum_11 =
    block_11[0:0];

assign carry_11 =
    block_11[1];

wire [4:0] block_12_0;
wire [4:0] block_12_1;
wire [4:0] block_12;
wire [3:0] sum_12;
wire carry_12;

assign block_12_0 =
    {1'b0, a_i[20:17]} +
    {1'b0, b_i[20:17]};

assign block_12_1 =
    {1'b0, a_i[20:17]} +
    {1'b0, b_i[20:17]} +
    5'd1;

assign block_12 =
    carry_11
    ? block_12_1
    : block_12_0;

assign sum_12 =
    block_12[3:0];

assign carry_12 =
    block_12[4];

wire [2:0] block_13_0;
wire [2:0] block_13_1;
wire [2:0] block_13;
wire [1:0] sum_13;
wire carry_13;

assign block_13_0 =
    {1'b0, a_i[22:21]} +
    {1'b0, b_i[22:21]};

assign block_13_1 =
    {1'b0, a_i[22:21]} +
    {1'b0, b_i[22:21]} +
    3'd1;

assign block_13 =
    carry_12
    ? block_13_1
    : block_13_0;

assign sum_13 =
    block_13[1:0];

assign carry_13 =
    block_13[2];

wire [5:0] block_14_0;
wire [5:0] block_14_1;
wire [5:0] block_14;
wire [4:0] sum_14;
wire carry_14;

assign block_14_0 =
    {1'b0, a_i[27:23]} +
    {1'b0, b_i[27:23]};

assign block_14_1 =
    {1'b0, a_i[27:23]} +
    {1'b0, b_i[27:23]} +
    6'd1;

assign block_14 =
    carry_13
    ? block_14_1
    : block_14_0;

assign sum_14 =
    block_14[4:0];

assign carry_14 =
    block_14[5];

wire [2:0] block_15_0;
wire [2:0] block_15_1;
wire [2:0] block_15;
wire [1:0] sum_15;
wire carry_15;

assign block_15_0 =
    {1'b0, a_i[29:28]} +
    {1'b0, b_i[29:28]};

assign block_15_1 =
    {1'b0, a_i[29:28]} +
    {1'b0, b_i[29:28]} +
    3'd1;

assign block_15 =
    carry_14
    ? block_15_1
    : block_15_0;

assign sum_15 =
    block_15[1:0];

assign carry_15 =
    block_15[2];

wire [2:0] block_16_0;
wire [2:0] block_16_1;
wire [2:0] block_16;
wire [1:0] sum_16;
wire carry_16;

assign block_16_0 =
    {1'b0, a_i[31:30]} +
    {1'b0, b_i[31:30]};

assign block_16_1 =
    {1'b0, a_i[31:30]} +
    {1'b0, b_i[31:30]} +
    3'd1;

assign block_16 =
    carry_15
    ? block_16_1
    : block_16_0;

assign sum_16 =
    block_16[1:0];

assign carry_16 =
    block_16[2];

wire [31:0] sum;

assign sum = {
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
        y_o     <= 32'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

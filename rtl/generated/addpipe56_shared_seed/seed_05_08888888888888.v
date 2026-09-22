module addpipe56 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [55:0] a_i,
    input  wire [55:0] b_i,
    output reg         valid_o,
    output reg  [55:0] y_o
);

wire [4:0] block_0;
wire [3:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[3:0]} +
    {1'b0, b_i[3:0]};

assign sum_0 =
    block_0[3:0];

assign carry_0 =
    block_0[4];

wire [4:0] block_1_0;
wire [4:0] block_1_1;
wire [4:0] block_1;
wire [3:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[7:4]} +
    {1'b0, b_i[7:4]};

assign block_1_1 =
    {1'b0, a_i[7:4]} +
    {1'b0, b_i[7:4]} +
    5'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[3:0];

assign carry_1 =
    block_1[4];

wire [4:0] block_2_0;
wire [4:0] block_2_1;
wire [4:0] block_2;
wire [3:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[11:8]} +
    {1'b0, b_i[11:8]};

assign block_2_1 =
    {1'b0, a_i[11:8]} +
    {1'b0, b_i[11:8]} +
    5'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[3:0];

assign carry_2 =
    block_2[4];

wire [4:0] block_3_0;
wire [4:0] block_3_1;
wire [4:0] block_3;
wire [3:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[15:12]} +
    {1'b0, b_i[15:12]};

assign block_3_1 =
    {1'b0, a_i[15:12]} +
    {1'b0, b_i[15:12]} +
    5'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[3:0];

assign carry_3 =
    block_3[4];

wire [4:0] block_4_0;
wire [4:0] block_4_1;
wire [4:0] block_4;
wire [3:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[19:16]} +
    {1'b0, b_i[19:16]};

assign block_4_1 =
    {1'b0, a_i[19:16]} +
    {1'b0, b_i[19:16]} +
    5'd1;

assign block_4 =
    carry_3
    ? block_4_1
    : block_4_0;

assign sum_4 =
    block_4[3:0];

assign carry_4 =
    block_4[4];

wire [4:0] block_5_0;
wire [4:0] block_5_1;
wire [4:0] block_5;
wire [3:0] sum_5;
wire carry_5;

assign block_5_0 =
    {1'b0, a_i[23:20]} +
    {1'b0, b_i[23:20]};

assign block_5_1 =
    {1'b0, a_i[23:20]} +
    {1'b0, b_i[23:20]} +
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
    {1'b0, a_i[27:24]} +
    {1'b0, b_i[27:24]};

assign block_6_1 =
    {1'b0, a_i[27:24]} +
    {1'b0, b_i[27:24]} +
    5'd1;

assign block_6 =
    carry_5
    ? block_6_1
    : block_6_0;

assign sum_6 =
    block_6[3:0];

assign carry_6 =
    block_6[4];

wire [4:0] block_7_0;
wire [4:0] block_7_1;
wire [4:0] block_7;
wire [3:0] sum_7;
wire carry_7;

assign block_7_0 =
    {1'b0, a_i[31:28]} +
    {1'b0, b_i[31:28]};

assign block_7_1 =
    {1'b0, a_i[31:28]} +
    {1'b0, b_i[31:28]} +
    5'd1;

assign block_7 =
    carry_6
    ? block_7_1
    : block_7_0;

assign sum_7 =
    block_7[3:0];

assign carry_7 =
    block_7[4];

wire [4:0] block_8_0;
wire [4:0] block_8_1;
wire [4:0] block_8;
wire [3:0] sum_8;
wire carry_8;

assign block_8_0 =
    {1'b0, a_i[35:32]} +
    {1'b0, b_i[35:32]};

assign block_8_1 =
    {1'b0, a_i[35:32]} +
    {1'b0, b_i[35:32]} +
    5'd1;

assign block_8 =
    carry_7
    ? block_8_1
    : block_8_0;

assign sum_8 =
    block_8[3:0];

assign carry_8 =
    block_8[4];

wire [4:0] block_9_0;
wire [4:0] block_9_1;
wire [4:0] block_9;
wire [3:0] sum_9;
wire carry_9;

assign block_9_0 =
    {1'b0, a_i[39:36]} +
    {1'b0, b_i[39:36]};

assign block_9_1 =
    {1'b0, a_i[39:36]} +
    {1'b0, b_i[39:36]} +
    5'd1;

assign block_9 =
    carry_8
    ? block_9_1
    : block_9_0;

assign sum_9 =
    block_9[3:0];

assign carry_9 =
    block_9[4];

wire [4:0] block_10_0;
wire [4:0] block_10_1;
wire [4:0] block_10;
wire [3:0] sum_10;
wire carry_10;

assign block_10_0 =
    {1'b0, a_i[43:40]} +
    {1'b0, b_i[43:40]};

assign block_10_1 =
    {1'b0, a_i[43:40]} +
    {1'b0, b_i[43:40]} +
    5'd1;

assign block_10 =
    carry_9
    ? block_10_1
    : block_10_0;

assign sum_10 =
    block_10[3:0];

assign carry_10 =
    block_10[4];

wire [4:0] block_11_0;
wire [4:0] block_11_1;
wire [4:0] block_11;
wire [3:0] sum_11;
wire carry_11;

assign block_11_0 =
    {1'b0, a_i[47:44]} +
    {1'b0, b_i[47:44]};

assign block_11_1 =
    {1'b0, a_i[47:44]} +
    {1'b0, b_i[47:44]} +
    5'd1;

assign block_11 =
    carry_10
    ? block_11_1
    : block_11_0;

assign sum_11 =
    block_11[3:0];

assign carry_11 =
    block_11[4];

wire [4:0] block_12_0;
wire [4:0] block_12_1;
wire [4:0] block_12;
wire [3:0] sum_12;
wire carry_12;

assign block_12_0 =
    {1'b0, a_i[51:48]} +
    {1'b0, b_i[51:48]};

assign block_12_1 =
    {1'b0, a_i[51:48]} +
    {1'b0, b_i[51:48]} +
    5'd1;

assign block_12 =
    carry_11
    ? block_12_1
    : block_12_0;

assign sum_12 =
    block_12[3:0];

assign carry_12 =
    block_12[4];

wire [4:0] block_13_0;
wire [4:0] block_13_1;
wire [4:0] block_13;
wire [3:0] sum_13;
wire carry_13;

assign block_13_0 =
    {1'b0, a_i[55:52]} +
    {1'b0, b_i[55:52]};

assign block_13_1 =
    {1'b0, a_i[55:52]} +
    {1'b0, b_i[55:52]} +
    5'd1;

assign block_13 =
    carry_12
    ? block_13_1
    : block_13_0;

assign sum_13 =
    block_13[3:0];

assign carry_13 =
    block_13[4];

wire [55:0] sum;

assign sum = {
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

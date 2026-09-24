module addpipe56 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [55:0] a_i,
    input  wire [55:0] b_i,
    output reg         valid_o,
    output reg  [55:0] y_o
);

wire [5:0] block_0;
wire [4:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[4:0]} +
    {1'b0, b_i[4:0]};

assign sum_0 =
    block_0[4:0];

assign carry_0 =
    block_0[5];

wire [8:0] block_1_0;
wire [8:0] block_1_1;
wire [8:0] block_1;
wire [7:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[12:5]} +
    {1'b0, b_i[12:5]};

assign block_1_1 =
    {1'b0, a_i[12:5]} +
    {1'b0, b_i[12:5]} +
    9'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[7:0];

assign carry_1 =
    block_1[8];

wire [1:0] block_2_0;
wire [1:0] block_2_1;
wire [1:0] block_2;
wire [0:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[13]} +
    {1'b0, b_i[13]};

assign block_2_1 =
    {1'b0, a_i[13]} +
    {1'b0, b_i[13]} +
    2'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[0:0];

assign carry_2 =
    block_2[1];

wire [10:0] block_3_0;
wire [10:0] block_3_1;
wire [10:0] block_3;
wire [9:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[23:14]} +
    {1'b0, b_i[23:14]};

assign block_3_1 =
    {1'b0, a_i[23:14]} +
    {1'b0, b_i[23:14]} +
    11'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[9:0];

assign carry_3 =
    block_3[10];

wire [15:0] block_4_0;
wire [15:0] block_4_1;
wire [15:0] block_4;
wire [14:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[38:24]} +
    {1'b0, b_i[38:24]};

assign block_4_1 =
    {1'b0, a_i[38:24]} +
    {1'b0, b_i[38:24]} +
    16'd1;

assign block_4 =
    carry_3
    ? block_4_1
    : block_4_0;

assign sum_4 =
    block_4[14:0];

assign carry_4 =
    block_4[15];

wire [11:0] block_5_0;
wire [11:0] block_5_1;
wire [11:0] block_5;
wire [10:0] sum_5;
wire carry_5;

assign block_5_0 =
    {1'b0, a_i[49:39]} +
    {1'b0, b_i[49:39]};

assign block_5_1 =
    {1'b0, a_i[49:39]} +
    {1'b0, b_i[49:39]} +
    12'd1;

assign block_5 =
    carry_4
    ? block_5_1
    : block_5_0;

assign sum_5 =
    block_5[10:0];

assign carry_5 =
    block_5[11];

wire [5:0] block_6_0;
wire [5:0] block_6_1;
wire [5:0] block_6;
wire [4:0] sum_6;
wire carry_6;

assign block_6_0 =
    {1'b0, a_i[54:50]} +
    {1'b0, b_i[54:50]};

assign block_6_1 =
    {1'b0, a_i[54:50]} +
    {1'b0, b_i[54:50]} +
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
    {1'b0, a_i[55]} +
    {1'b0, b_i[55]};

assign block_7_1 =
    {1'b0, a_i[55]} +
    {1'b0, b_i[55]} +
    2'd1;

assign block_7 =
    carry_6
    ? block_7_1
    : block_7_0;

assign sum_7 =
    block_7[0:0];

assign carry_7 =
    block_7[1];

wire [55:0] sum;

assign sum = {
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

module addpipe24 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [23:0] a_i,
    input  wire [23:0] b_i,
    output reg         valid_o,
    output reg  [23:0] y_o
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

wire [3:0] block_1_0;
wire [3:0] block_1_1;
wire [3:0] block_1;
wire [2:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[3:1]} +
    {1'b0, b_i[3:1]};

assign block_1_1 =
    {1'b0, a_i[3:1]} +
    {1'b0, b_i[3:1]} +
    4'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[2:0];

assign carry_1 =
    block_1[3];

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

wire [2:0] block_3_0;
wire [2:0] block_3_1;
wire [2:0] block_3;
wire [1:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[6:5]} +
    {1'b0, b_i[6:5]};

assign block_3_1 =
    {1'b0, a_i[6:5]} +
    {1'b0, b_i[6:5]} +
    3'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[1:0];

assign carry_3 =
    block_3[2];

wire [4:0] block_4_0;
wire [4:0] block_4_1;
wire [4:0] block_4;
wire [3:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[10:7]} +
    {1'b0, b_i[10:7]};

assign block_4_1 =
    {1'b0, a_i[10:7]} +
    {1'b0, b_i[10:7]} +
    5'd1;

assign block_4 =
    carry_3
    ? block_4_1
    : block_4_0;

assign sum_4 =
    block_4[3:0];

assign carry_4 =
    block_4[4];

wire [3:0] block_5_0;
wire [3:0] block_5_1;
wire [3:0] block_5;
wire [2:0] sum_5;
wire carry_5;

assign block_5_0 =
    {1'b0, a_i[13:11]} +
    {1'b0, b_i[13:11]};

assign block_5_1 =
    {1'b0, a_i[13:11]} +
    {1'b0, b_i[13:11]} +
    4'd1;

assign block_5 =
    carry_4
    ? block_5_1
    : block_5_0;

assign sum_5 =
    block_5[2:0];

assign carry_5 =
    block_5[3];

wire [2:0] block_6_0;
wire [2:0] block_6_1;
wire [2:0] block_6;
wire [1:0] sum_6;
wire carry_6;

assign block_6_0 =
    {1'b0, a_i[15:14]} +
    {1'b0, b_i[15:14]};

assign block_6_1 =
    {1'b0, a_i[15:14]} +
    {1'b0, b_i[15:14]} +
    3'd1;

assign block_6 =
    carry_5
    ? block_6_1
    : block_6_0;

assign sum_6 =
    block_6[1:0];

assign carry_6 =
    block_6[2];

wire [1:0] block_7_0;
wire [1:0] block_7_1;
wire [1:0] block_7;
wire [0:0] sum_7;
wire carry_7;

assign block_7_0 =
    {1'b0, a_i[16]} +
    {1'b0, b_i[16]};

assign block_7_1 =
    {1'b0, a_i[16]} +
    {1'b0, b_i[16]} +
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
    {1'b0, a_i[17]} +
    {1'b0, b_i[17]};

assign block_8_1 =
    {1'b0, a_i[17]} +
    {1'b0, b_i[17]} +
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
    {1'b0, a_i[19:18]} +
    {1'b0, b_i[19:18]};

assign block_9_1 =
    {1'b0, a_i[19:18]} +
    {1'b0, b_i[19:18]} +
    3'd1;

assign block_9 =
    carry_8
    ? block_9_1
    : block_9_0;

assign sum_9 =
    block_9[1:0];

assign carry_9 =
    block_9[2];

wire [4:0] block_10_0;
wire [4:0] block_10_1;
wire [4:0] block_10;
wire [3:0] sum_10;
wire carry_10;

assign block_10_0 =
    {1'b0, a_i[23:20]} +
    {1'b0, b_i[23:20]};

assign block_10_1 =
    {1'b0, a_i[23:20]} +
    {1'b0, b_i[23:20]} +
    5'd1;

assign block_10 =
    carry_9
    ? block_10_1
    : block_10_0;

assign sum_10 =
    block_10[3:0];

assign carry_10 =
    block_10[4];

wire [23:0] sum;

assign sum = {
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
        y_o     <= 24'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

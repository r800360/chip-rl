module addpipe40 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [39:0] a_i,
    input  wire [39:0] b_i,
    output reg         valid_o,
    output reg  [39:0] y_o
);

wire [11:0] block_0;
wire [10:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[10:0]} +
    {1'b0, b_i[10:0]};

assign sum_0 =
    block_0[10:0];

assign carry_0 =
    block_0[11];

wire [12:0] block_1_0;
wire [12:0] block_1_1;
wire [12:0] block_1;
wire [11:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[22:11]} +
    {1'b0, b_i[22:11]};

assign block_1_1 =
    {1'b0, a_i[22:11]} +
    {1'b0, b_i[22:11]} +
    13'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[11:0];

assign carry_1 =
    block_1[12];

wire [5:0] block_2_0;
wire [5:0] block_2_1;
wire [5:0] block_2;
wire [4:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[27:23]} +
    {1'b0, b_i[27:23]};

assign block_2_1 =
    {1'b0, a_i[27:23]} +
    {1'b0, b_i[27:23]} +
    6'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[4:0];

assign carry_2 =
    block_2[5];

wire [5:0] block_3_0;
wire [5:0] block_3_1;
wire [5:0] block_3;
wire [4:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[32:28]} +
    {1'b0, b_i[32:28]};

assign block_3_1 =
    {1'b0, a_i[32:28]} +
    {1'b0, b_i[32:28]} +
    6'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[4:0];

assign carry_3 =
    block_3[5];

wire [1:0] block_4_0;
wire [1:0] block_4_1;
wire [1:0] block_4;
wire [0:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[33]} +
    {1'b0, b_i[33]};

assign block_4_1 =
    {1'b0, a_i[33]} +
    {1'b0, b_i[33]} +
    2'd1;

assign block_4 =
    carry_3
    ? block_4_1
    : block_4_0;

assign sum_4 =
    block_4[0:0];

assign carry_4 =
    block_4[1];

wire [5:0] block_5_0;
wire [5:0] block_5_1;
wire [5:0] block_5;
wire [4:0] sum_5;
wire carry_5;

assign block_5_0 =
    {1'b0, a_i[38:34]} +
    {1'b0, b_i[38:34]};

assign block_5_1 =
    {1'b0, a_i[38:34]} +
    {1'b0, b_i[38:34]} +
    6'd1;

assign block_5 =
    carry_4
    ? block_5_1
    : block_5_0;

assign sum_5 =
    block_5[4:0];

assign carry_5 =
    block_5[5];

wire [1:0] block_6_0;
wire [1:0] block_6_1;
wire [1:0] block_6;
wire [0:0] sum_6;
wire carry_6;

assign block_6_0 =
    {1'b0, a_i[39]} +
    {1'b0, b_i[39]};

assign block_6_1 =
    {1'b0, a_i[39]} +
    {1'b0, b_i[39]} +
    2'd1;

assign block_6 =
    carry_5
    ? block_6_1
    : block_6_0;

assign sum_6 =
    block_6[0:0];

assign carry_6 =
    block_6[1];

wire [39:0] sum;

assign sum = {
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

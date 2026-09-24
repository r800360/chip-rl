module addpipe56 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [55:0] a_i,
    input  wire [55:0] b_i,
    output reg         valid_o,
    output reg  [55:0] y_o
);

wire [16:0] block_0;
wire [15:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[15:0]} +
    {1'b0, b_i[15:0]};

assign sum_0 =
    block_0[15:0];

assign carry_0 =
    block_0[16];

wire [9:0] block_1_0;
wire [9:0] block_1_1;
wire [9:0] block_1;
wire [8:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[24:16]} +
    {1'b0, b_i[24:16]};

assign block_1_1 =
    {1'b0, a_i[24:16]} +
    {1'b0, b_i[24:16]} +
    10'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[8:0];

assign carry_1 =
    block_1[9];

wire [9:0] block_2_0;
wire [9:0] block_2_1;
wire [9:0] block_2;
wire [8:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[33:25]} +
    {1'b0, b_i[33:25]};

assign block_2_1 =
    {1'b0, a_i[33:25]} +
    {1'b0, b_i[33:25]} +
    10'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[8:0];

assign carry_2 =
    block_2[9];

wire [14:0] block_3_0;
wire [14:0] block_3_1;
wire [14:0] block_3;
wire [13:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[47:34]} +
    {1'b0, b_i[47:34]};

assign block_3_1 =
    {1'b0, a_i[47:34]} +
    {1'b0, b_i[47:34]} +
    15'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[13:0];

assign carry_3 =
    block_3[14];

wire [8:0] block_4_0;
wire [8:0] block_4_1;
wire [8:0] block_4;
wire [7:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[55:48]} +
    {1'b0, b_i[55:48]};

assign block_4_1 =
    {1'b0, a_i[55:48]} +
    {1'b0, b_i[55:48]} +
    9'd1;

assign block_4 =
    carry_3
    ? block_4_1
    : block_4_0;

assign sum_4 =
    block_4[7:0];

assign carry_4 =
    block_4[8];

wire [55:0] sum;

assign sum = {
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

module addpipe56 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [55:0] a_i,
    input  wire [55:0] b_i,
    output reg         valid_o,
    output reg  [55:0] y_o
);

wire [14:0] block_0;
wire [13:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[13:0]} +
    {1'b0, b_i[13:0]};

assign sum_0 =
    block_0[13:0];

assign carry_0 =
    block_0[14];

wire [1:0] block_1_0;
wire [1:0] block_1_1;
wire [1:0] block_1;
wire [0:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[14]} +
    {1'b0, b_i[14]};

assign block_1_1 =
    {1'b0, a_i[14]} +
    {1'b0, b_i[14]} +
    2'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[0:0];

assign carry_1 =
    block_1[1];

wire [33:0] block_2_0;
wire [33:0] block_2_1;
wire [33:0] block_2;
wire [32:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[47:15]} +
    {1'b0, b_i[47:15]};

assign block_2_1 =
    {1'b0, a_i[47:15]} +
    {1'b0, b_i[47:15]} +
    34'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[32:0];

assign carry_2 =
    block_2[33];

wire [5:0] block_3_0;
wire [5:0] block_3_1;
wire [5:0] block_3;
wire [4:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[52:48]} +
    {1'b0, b_i[52:48]};

assign block_3_1 =
    {1'b0, a_i[52:48]} +
    {1'b0, b_i[52:48]} +
    6'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[4:0];

assign carry_3 =
    block_3[5];

wire [3:0] block_4_0;
wire [3:0] block_4_1;
wire [3:0] block_4;
wire [2:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[55:53]} +
    {1'b0, b_i[55:53]};

assign block_4_1 =
    {1'b0, a_i[55:53]} +
    {1'b0, b_i[55:53]} +
    4'd1;

assign block_4 =
    carry_3
    ? block_4_1
    : block_4_0;

assign sum_4 =
    block_4[2:0];

assign carry_4 =
    block_4[3];

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

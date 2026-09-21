module addpipe24 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [23:0] a_i,
    input  wire [23:0] b_i,
    output reg         valid_o,
    output reg  [23:0] y_o
);

wire [6:0] block_0;
wire [5:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[5:0]} +
    {1'b0, b_i[5:0]};

assign sum_0 =
    block_0[5:0];

assign carry_0 =
    block_0[6];

wire [6:0] block_1_0;
wire [6:0] block_1_1;
wire [6:0] block_1;
wire [5:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[11:6]} +
    {1'b0, b_i[11:6]};

assign block_1_1 =
    {1'b0, a_i[11:6]} +
    {1'b0, b_i[11:6]} +
    7'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[5:0];

assign carry_1 =
    block_1[6];

wire [5:0] block_2_0;
wire [5:0] block_2_1;
wire [5:0] block_2;
wire [4:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[16:12]} +
    {1'b0, b_i[16:12]};

assign block_2_1 =
    {1'b0, a_i[16:12]} +
    {1'b0, b_i[16:12]} +
    6'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[4:0];

assign carry_2 =
    block_2[5];

wire [3:0] block_3_0;
wire [3:0] block_3_1;
wire [3:0] block_3;
wire [2:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[19:17]} +
    {1'b0, b_i[19:17]};

assign block_3_1 =
    {1'b0, a_i[19:17]} +
    {1'b0, b_i[19:17]} +
    4'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[2:0];

assign carry_3 =
    block_3[3];

wire [1:0] block_4_0;
wire [1:0] block_4_1;
wire [1:0] block_4;
wire [0:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[20]} +
    {1'b0, b_i[20]};

assign block_4_1 =
    {1'b0, a_i[20]} +
    {1'b0, b_i[20]} +
    2'd1;

assign block_4 =
    carry_3
    ? block_4_1
    : block_4_0;

assign sum_4 =
    block_4[0:0];

assign carry_4 =
    block_4[1];

wire [3:0] block_5_0;
wire [3:0] block_5_1;
wire [3:0] block_5;
wire [2:0] sum_5;
wire carry_5;

assign block_5_0 =
    {1'b0, a_i[23:21]} +
    {1'b0, b_i[23:21]};

assign block_5_1 =
    {1'b0, a_i[23:21]} +
    {1'b0, b_i[23:21]} +
    4'd1;

assign block_5 =
    carry_4
    ? block_5_1
    : block_5_0;

assign sum_5 =
    block_5[2:0];

assign carry_5 =
    block_5[3];

wire [23:0] sum;

assign sum = {
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

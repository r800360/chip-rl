module addpipe36 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [35:0] a_i,
    input  wire [35:0] b_i,
    output reg         valid_o,
    output reg  [35:0] y_o
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

wire [4:0] block_1_0;
wire [4:0] block_1_1;
wire [4:0] block_1;
wire [3:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[8:5]} +
    {1'b0, b_i[8:5]};

assign block_1_1 =
    {1'b0, a_i[8:5]} +
    {1'b0, b_i[8:5]} +
    5'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[3:0];

assign carry_1 =
    block_1[4];

wire [19:0] block_2_0;
wire [19:0] block_2_1;
wire [19:0] block_2;
wire [18:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[27:9]} +
    {1'b0, b_i[27:9]};

assign block_2_1 =
    {1'b0, a_i[27:9]} +
    {1'b0, b_i[27:9]} +
    20'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[18:0];

assign carry_2 =
    block_2[19];

wire [7:0] block_3_0;
wire [7:0] block_3_1;
wire [7:0] block_3;
wire [6:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[34:28]} +
    {1'b0, b_i[34:28]};

assign block_3_1 =
    {1'b0, a_i[34:28]} +
    {1'b0, b_i[34:28]} +
    8'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[6:0];

assign carry_3 =
    block_3[7];

wire [1:0] block_4_0;
wire [1:0] block_4_1;
wire [1:0] block_4;
wire [0:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[35]} +
    {1'b0, b_i[35]};

assign block_4_1 =
    {1'b0, a_i[35]} +
    {1'b0, b_i[35]} +
    2'd1;

assign block_4 =
    carry_3
    ? block_4_1
    : block_4_0;

assign sum_4 =
    block_4[0:0];

assign carry_4 =
    block_4[1];

wire [35:0] sum;

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
        y_o     <= 36'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

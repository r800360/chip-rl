module addpipe56 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [55:0] a_i,
    input  wire [55:0] b_i,
    output reg         valid_o,
    output reg  [55:0] y_o
);

wire [3:0] block_0;
wire [2:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[2:0]} +
    {1'b0, b_i[2:0]};

assign sum_0 =
    block_0[2:0];

assign carry_0 =
    block_0[3];

wire [33:0] block_1_0;
wire [33:0] block_1_1;
wire [33:0] block_1;
wire [32:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[35:3]} +
    {1'b0, b_i[35:3]};

assign block_1_1 =
    {1'b0, a_i[35:3]} +
    {1'b0, b_i[35:3]} +
    34'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[32:0];

assign carry_1 =
    block_1[33];

wire [12:0] block_2_0;
wire [12:0] block_2_1;
wire [12:0] block_2;
wire [11:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[47:36]} +
    {1'b0, b_i[47:36]};

assign block_2_1 =
    {1'b0, a_i[47:36]} +
    {1'b0, b_i[47:36]} +
    13'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[11:0];

assign carry_2 =
    block_2[12];

wire [8:0] block_3_0;
wire [8:0] block_3_1;
wire [8:0] block_3;
wire [7:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[55:48]} +
    {1'b0, b_i[55:48]};

assign block_3_1 =
    {1'b0, a_i[55:48]} +
    {1'b0, b_i[55:48]} +
    9'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[7:0];

assign carry_3 =
    block_3[8];

wire [55:0] sum;

assign sum = {
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

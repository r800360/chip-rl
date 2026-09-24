module addpipe56 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [55:0] a_i,
    input  wire [55:0] b_i,
    output reg         valid_o,
    output reg  [55:0] y_o
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

wire [52:0] block_1_0;
wire [52:0] block_1_1;
wire [52:0] block_1;
wire [51:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[52:1]} +
    {1'b0, b_i[52:1]};

assign block_1_1 =
    {1'b0, a_i[52:1]} +
    {1'b0, b_i[52:1]} +
    53'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[51:0];

assign carry_1 =
    block_1[52];

wire [3:0] block_2_0;
wire [3:0] block_2_1;
wire [3:0] block_2;
wire [2:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[55:53]} +
    {1'b0, b_i[55:53]};

assign block_2_1 =
    {1'b0, a_i[55:53]} +
    {1'b0, b_i[55:53]} +
    4'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[2:0];

assign carry_2 =
    block_2[3];

wire [55:0] sum;

assign sum = {
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

module addpipe40 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [39:0] a_i,
    input  wire [39:0] b_i,
    output reg         valid_o,
    output reg  [39:0] y_o
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

wire [27:0] block_1_0;
wire [27:0] block_1_1;
wire [27:0] block_1;
wire [26:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[31:5]} +
    {1'b0, b_i[31:5]};

assign block_1_1 =
    {1'b0, a_i[31:5]} +
    {1'b0, b_i[31:5]} +
    28'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[26:0];

assign carry_1 =
    block_1[27];

wire [3:0] block_2_0;
wire [3:0] block_2_1;
wire [3:0] block_2;
wire [2:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[34:32]} +
    {1'b0, b_i[34:32]};

assign block_2_1 =
    {1'b0, a_i[34:32]} +
    {1'b0, b_i[34:32]} +
    4'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[2:0];

assign carry_2 =
    block_2[3];

wire [5:0] block_3_0;
wire [5:0] block_3_1;
wire [5:0] block_3;
wire [4:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[39:35]} +
    {1'b0, b_i[39:35]};

assign block_3_1 =
    {1'b0, a_i[39:35]} +
    {1'b0, b_i[39:35]} +
    6'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[4:0];

assign carry_3 =
    block_3[5];

wire [39:0] sum;

assign sum = {
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

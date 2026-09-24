module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

wire [4:0] block_0;
wire [3:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[3:0]} +
    {1'b0, b_i[3:0]};

assign sum_0 =
    block_0[3:0];

assign carry_0 =
    block_0[4];

wire [24:0] block_1_0;
wire [24:0] block_1_1;
wire [24:0] block_1;
wire [23:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[27:4]} +
    {1'b0, b_i[27:4]};

assign block_1_1 =
    {1'b0, a_i[27:4]} +
    {1'b0, b_i[27:4]} +
    25'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[23:0];

assign carry_1 =
    block_1[24];

wire [4:0] block_2_0;
wire [4:0] block_2_1;
wire [4:0] block_2;
wire [3:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[31:28]} +
    {1'b0, b_i[31:28]};

assign block_2_1 =
    {1'b0, a_i[31:28]} +
    {1'b0, b_i[31:28]} +
    5'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[3:0];

assign carry_2 =
    block_2[4];

wire [31:0] sum;

assign sum = {
    sum_2,
    sum_1,
    sum_0
};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 32'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

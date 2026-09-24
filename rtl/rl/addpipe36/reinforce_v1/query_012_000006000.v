module addpipe36 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [35:0] a_i,
    input  wire [35:0] b_i,
    output reg         valid_o,
    output reg  [35:0] y_o
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

wire [21:0] block_2_0;
wire [21:0] block_2_1;
wire [21:0] block_2;
wire [20:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[35:15]} +
    {1'b0, b_i[35:15]};

assign block_2_1 =
    {1'b0, a_i[35:15]} +
    {1'b0, b_i[35:15]} +
    22'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[20:0];

assign carry_2 =
    block_2[21];

wire [35:0] sum;

assign sum = {
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

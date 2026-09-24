module addpipe36 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [35:0] a_i,
    input  wire [35:0] b_i,
    output reg         valid_o,
    output reg  [35:0] y_o
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

wire [27:0] block_1_0;
wire [27:0] block_1_1;
wire [27:0] block_1;
wire [26:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[30:4]} +
    {1'b0, b_i[30:4]};

assign block_1_1 =
    {1'b0, a_i[30:4]} +
    {1'b0, b_i[30:4]} +
    28'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[26:0];

assign carry_1 =
    block_1[27];

wire [5:0] block_2_0;
wire [5:0] block_2_1;
wire [5:0] block_2;
wire [4:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[35:31]} +
    {1'b0, b_i[35:31]};

assign block_2_1 =
    {1'b0, a_i[35:31]} +
    {1'b0, b_i[35:31]} +
    6'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[4:0];

assign carry_2 =
    block_2[5];

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

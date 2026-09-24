module addpipe36 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [35:0] a_i,
    input  wire [35:0] b_i,
    output reg         valid_o,
    output reg  [35:0] y_o
);

wire [11:0] block_0;
wire [10:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[10:0]} +
    {1'b0, b_i[10:0]};

assign sum_0 =
    block_0[10:0];

assign carry_0 =
    block_0[11];

wire [14:0] block_1_0;
wire [14:0] block_1_1;
wire [14:0] block_1;
wire [13:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[24:11]} +
    {1'b0, b_i[24:11]};

assign block_1_1 =
    {1'b0, a_i[24:11]} +
    {1'b0, b_i[24:11]} +
    15'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[13:0];

assign carry_1 =
    block_1[14];

wire [7:0] block_2_0;
wire [7:0] block_2_1;
wire [7:0] block_2;
wire [6:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[31:25]} +
    {1'b0, b_i[31:25]};

assign block_2_1 =
    {1'b0, a_i[31:25]} +
    {1'b0, b_i[31:25]} +
    8'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[6:0];

assign carry_2 =
    block_2[7];

wire [4:0] block_3_0;
wire [4:0] block_3_1;
wire [4:0] block_3;
wire [3:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[35:32]} +
    {1'b0, b_i[35:32]};

assign block_3_1 =
    {1'b0, a_i[35:32]} +
    {1'b0, b_i[35:32]} +
    5'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[3:0];

assign carry_3 =
    block_3[4];

wire [35:0] sum;

assign sum = {
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

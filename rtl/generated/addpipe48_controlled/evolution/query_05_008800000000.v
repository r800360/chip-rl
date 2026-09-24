module addpipe48 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [47:0] a_i,
    input  wire [47:0] b_i,
    output reg         valid_o,
    output reg  [47:0] y_o
);

wire [36:0] block_0;
wire [35:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[35:0]} +
    {1'b0, b_i[35:0]};

assign sum_0 =
    block_0[35:0];

assign carry_0 =
    block_0[36];

wire [4:0] block_1_0;
wire [4:0] block_1_1;
wire [4:0] block_1;
wire [3:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[39:36]} +
    {1'b0, b_i[39:36]};

assign block_1_1 =
    {1'b0, a_i[39:36]} +
    {1'b0, b_i[39:36]} +
    5'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[3:0];

assign carry_1 =
    block_1[4];

wire [8:0] block_2_0;
wire [8:0] block_2_1;
wire [8:0] block_2;
wire [7:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[47:40]} +
    {1'b0, b_i[47:40]};

assign block_2_1 =
    {1'b0, a_i[47:40]} +
    {1'b0, b_i[47:40]} +
    9'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[7:0];

assign carry_2 =
    block_2[8];

wire [47:0] sum;

assign sum = {
    sum_2,
    sum_1,
    sum_0
};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 48'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

module addpipe24 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [23:0] a_i,
    input  wire [23:0] b_i,
    output reg         valid_o,
    output reg  [23:0] y_o
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

wire [7:0] block_1_0;
wire [7:0] block_1_1;
wire [7:0] block_1;
wire [6:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[11:5]} +
    {1'b0, b_i[11:5]};

assign block_1_1 =
    {1'b0, a_i[11:5]} +
    {1'b0, b_i[11:5]} +
    8'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[6:0];

assign carry_1 =
    block_1[7];

wire [12:0] block_2_0;
wire [12:0] block_2_1;
wire [12:0] block_2;
wire [11:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[23:12]} +
    {1'b0, b_i[23:12]};

assign block_2_1 =
    {1'b0, a_i[23:12]} +
    {1'b0, b_i[23:12]} +
    13'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[11:0];

assign carry_2 =
    block_2[12];

wire [23:0] sum;

assign sum = {
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

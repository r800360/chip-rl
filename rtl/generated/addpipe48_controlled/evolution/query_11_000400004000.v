module addpipe48 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [47:0] a_i,
    input  wire [47:0] b_i,
    output reg         valid_o,
    output reg  [47:0] y_o
);

wire [15:0] block_0;
wire [14:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[14:0]} +
    {1'b0, b_i[14:0]};

assign sum_0 =
    block_0[14:0];

assign carry_0 =
    block_0[15];

wire [20:0] block_1_0;
wire [20:0] block_1_1;
wire [20:0] block_1;
wire [19:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[34:15]} +
    {1'b0, b_i[34:15]};

assign block_1_1 =
    {1'b0, a_i[34:15]} +
    {1'b0, b_i[34:15]} +
    21'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[19:0];

assign carry_1 =
    block_1[20];

wire [13:0] block_2_0;
wire [13:0] block_2_1;
wire [13:0] block_2;
wire [12:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[47:35]} +
    {1'b0, b_i[47:35]};

assign block_2_1 =
    {1'b0, a_i[47:35]} +
    {1'b0, b_i[47:35]} +
    14'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[12:0];

assign carry_2 =
    block_2[13];

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

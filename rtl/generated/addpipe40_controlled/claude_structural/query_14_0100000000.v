module addpipe40 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [39:0] a_i,
    input  wire [39:0] b_i,
    output reg         valid_o,
    output reg  [39:0] y_o
);

wire [33:0] block_0;
wire [32:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[32:0]} +
    {1'b0, b_i[32:0]};

assign sum_0 =
    block_0[32:0];

assign carry_0 =
    block_0[33];

wire [7:0] block_1_0;
wire [7:0] block_1_1;
wire [7:0] block_1;
wire [6:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[39:33]} +
    {1'b0, b_i[39:33]};

assign block_1_1 =
    {1'b0, a_i[39:33]} +
    {1'b0, b_i[39:33]} +
    8'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[6:0];

assign carry_1 =
    block_1[7];

wire [39:0] sum;

assign sum = {
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

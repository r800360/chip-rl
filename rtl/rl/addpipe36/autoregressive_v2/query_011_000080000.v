module addpipe36 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [35:0] a_i,
    input  wire [35:0] b_i,
    output reg         valid_o,
    output reg  [35:0] y_o
);

wire [20:0] block_0;
wire [19:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[19:0]} +
    {1'b0, b_i[19:0]};

assign sum_0 =
    block_0[19:0];

assign carry_0 =
    block_0[20];

wire [16:0] block_1_0;
wire [16:0] block_1_1;
wire [16:0] block_1;
wire [15:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[35:20]} +
    {1'b0, b_i[35:20]};

assign block_1_1 =
    {1'b0, a_i[35:20]} +
    {1'b0, b_i[35:20]} +
    17'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[15:0];

assign carry_1 =
    block_1[16];

wire [35:0] sum;

assign sum = {
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

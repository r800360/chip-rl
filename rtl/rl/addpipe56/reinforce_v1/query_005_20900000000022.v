module addpipe56 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [55:0] a_i,
    input  wire [55:0] b_i,
    output reg         valid_o,
    output reg  [55:0] y_o
);

wire [2:0] block_0;
wire [1:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[1:0]} +
    {1'b0, b_i[1:0]};

assign sum_0 =
    block_0[1:0];

assign carry_0 =
    block_0[2];

wire [4:0] block_1_0;
wire [4:0] block_1_1;
wire [4:0] block_1;
wire [3:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[5:2]} +
    {1'b0, b_i[5:2]};

assign block_1_1 =
    {1'b0, a_i[5:2]} +
    {1'b0, b_i[5:2]} +
    5'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[3:0];

assign carry_1 =
    block_1[4];

wire [39:0] block_2_0;
wire [39:0] block_2_1;
wire [39:0] block_2;
wire [38:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[44:6]} +
    {1'b0, b_i[44:6]};

assign block_2_1 =
    {1'b0, a_i[44:6]} +
    {1'b0, b_i[44:6]} +
    40'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[38:0];

assign carry_2 =
    block_2[39];

wire [3:0] block_3_0;
wire [3:0] block_3_1;
wire [3:0] block_3;
wire [2:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[47:45]} +
    {1'b0, b_i[47:45]};

assign block_3_1 =
    {1'b0, a_i[47:45]} +
    {1'b0, b_i[47:45]} +
    4'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[2:0];

assign carry_3 =
    block_3[3];

wire [6:0] block_4_0;
wire [6:0] block_4_1;
wire [6:0] block_4;
wire [5:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[53:48]} +
    {1'b0, b_i[53:48]};

assign block_4_1 =
    {1'b0, a_i[53:48]} +
    {1'b0, b_i[53:48]} +
    7'd1;

assign block_4 =
    carry_3
    ? block_4_1
    : block_4_0;

assign sum_4 =
    block_4[5:0];

assign carry_4 =
    block_4[6];

wire [2:0] block_5_0;
wire [2:0] block_5_1;
wire [2:0] block_5;
wire [1:0] sum_5;
wire carry_5;

assign block_5_0 =
    {1'b0, a_i[55:54]} +
    {1'b0, b_i[55:54]};

assign block_5_1 =
    {1'b0, a_i[55:54]} +
    {1'b0, b_i[55:54]} +
    3'd1;

assign block_5 =
    carry_4
    ? block_5_1
    : block_5_0;

assign sum_5 =
    block_5[1:0];

assign carry_5 =
    block_5[2];

wire [55:0] sum;

assign sum = {
    sum_5,
    sum_4,
    sum_3,
    sum_2,
    sum_1,
    sum_0
};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 56'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

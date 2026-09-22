module addpipe40 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [39:0] a_i,
    input  wire [39:0] b_i,
    output reg         valid_o,
    output reg  [39:0] y_o
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

wire [5:0] block_1_0;
wire [5:0] block_1_1;
wire [5:0] block_1;
wire [4:0] sum_1;
wire carry_1;

assign block_1_0 =
    {1'b0, a_i[9:5]} +
    {1'b0, b_i[9:5]};

assign block_1_1 =
    {1'b0, a_i[9:5]} +
    {1'b0, b_i[9:5]} +
    6'd1;

assign block_1 =
    carry_0
    ? block_1_1
    : block_1_0;

assign sum_1 =
    block_1[4:0];

assign carry_1 =
    block_1[5];

wire [5:0] block_2_0;
wire [5:0] block_2_1;
wire [5:0] block_2;
wire [4:0] sum_2;
wire carry_2;

assign block_2_0 =
    {1'b0, a_i[14:10]} +
    {1'b0, b_i[14:10]};

assign block_2_1 =
    {1'b0, a_i[14:10]} +
    {1'b0, b_i[14:10]} +
    6'd1;

assign block_2 =
    carry_1
    ? block_2_1
    : block_2_0;

assign sum_2 =
    block_2[4:0];

assign carry_2 =
    block_2[5];

wire [5:0] block_3_0;
wire [5:0] block_3_1;
wire [5:0] block_3;
wire [4:0] sum_3;
wire carry_3;

assign block_3_0 =
    {1'b0, a_i[19:15]} +
    {1'b0, b_i[19:15]};

assign block_3_1 =
    {1'b0, a_i[19:15]} +
    {1'b0, b_i[19:15]} +
    6'd1;

assign block_3 =
    carry_2
    ? block_3_1
    : block_3_0;

assign sum_3 =
    block_3[4:0];

assign carry_3 =
    block_3[5];

wire [5:0] block_4_0;
wire [5:0] block_4_1;
wire [5:0] block_4;
wire [4:0] sum_4;
wire carry_4;

assign block_4_0 =
    {1'b0, a_i[24:20]} +
    {1'b0, b_i[24:20]};

assign block_4_1 =
    {1'b0, a_i[24:20]} +
    {1'b0, b_i[24:20]} +
    6'd1;

assign block_4 =
    carry_3
    ? block_4_1
    : block_4_0;

assign sum_4 =
    block_4[4:0];

assign carry_4 =
    block_4[5];

wire [5:0] block_5_0;
wire [5:0] block_5_1;
wire [5:0] block_5;
wire [4:0] sum_5;
wire carry_5;

assign block_5_0 =
    {1'b0, a_i[29:25]} +
    {1'b0, b_i[29:25]};

assign block_5_1 =
    {1'b0, a_i[29:25]} +
    {1'b0, b_i[29:25]} +
    6'd1;

assign block_5 =
    carry_4
    ? block_5_1
    : block_5_0;

assign sum_5 =
    block_5[4:0];

assign carry_5 =
    block_5[5];

wire [5:0] block_6_0;
wire [5:0] block_6_1;
wire [5:0] block_6;
wire [4:0] sum_6;
wire carry_6;

assign block_6_0 =
    {1'b0, a_i[34:30]} +
    {1'b0, b_i[34:30]};

assign block_6_1 =
    {1'b0, a_i[34:30]} +
    {1'b0, b_i[34:30]} +
    6'd1;

assign block_6 =
    carry_5
    ? block_6_1
    : block_6_0;

assign sum_6 =
    block_6[4:0];

assign carry_6 =
    block_6[5];

wire [5:0] block_7_0;
wire [5:0] block_7_1;
wire [5:0] block_7;
wire [4:0] sum_7;
wire carry_7;

assign block_7_0 =
    {1'b0, a_i[39:35]} +
    {1'b0, b_i[39:35]};

assign block_7_1 =
    {1'b0, a_i[39:35]} +
    {1'b0, b_i[39:35]} +
    6'd1;

assign block_7 =
    carry_6
    ? block_7_1
    : block_7_0;

assign sum_7 =
    block_7[4:0];

assign carry_7 =
    block_7[5];

wire [39:0] sum;

assign sum = {
    sum_7,
    sum_6,
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
        y_o     <= 40'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

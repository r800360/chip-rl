module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg         valid_o,
    output reg  [15:0] y_o
);

wire [7:0] low_sum;
wire [8:0] low_carry;

wire [8:0] high0;
wire [8:0] high1;
wire [7:0] high_sum;

wire [15:0] sum;

assign low_carry[0] = 1'b0;

genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : low_ripple
        assign low_sum[i] =
            a_i[i] ^ b_i[i] ^ low_carry[i];

        assign low_carry[i + 1] =
            (a_i[i] & b_i[i]) |
            (a_i[i] & low_carry[i]) |
            (b_i[i] & low_carry[i]);
    end
endgenerate

assign high0 =
    {1'b0, a_i[15:8]} +
    {1'b0, b_i[15:8]};

assign high1 =
    {1'b0, a_i[15:8]} +
    {1'b0, b_i[15:8]} +
    9'd1;

assign high_sum =
    low_carry[8]
    ? high1[7:0]
    : high0[7:0];

assign sum = {
    high_sum,
    low_sum
};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 16'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

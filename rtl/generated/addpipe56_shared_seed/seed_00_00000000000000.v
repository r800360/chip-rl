module addpipe56 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [55:0] a_i,
    input  wire [55:0] b_i,
    output reg         valid_o,
    output reg  [55:0] y_o
);

wire [56:0] block_0;
wire [55:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[55:0]} +
    {1'b0, b_i[55:0]};

assign sum_0 =
    block_0[55:0];

assign carry_0 =
    block_0[56];

wire [55:0] sum;

assign sum = {
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

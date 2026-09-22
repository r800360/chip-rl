module addpipe36 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [35:0] a_i,
    input  wire [35:0] b_i,
    output reg         valid_o,
    output reg  [35:0] y_o
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

wire [35:0] sum;

assign sum = {
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

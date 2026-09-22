module addpipe48 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [47:0] a_i,
    input  wire [47:0] b_i,
    output reg         valid_o,
    output reg  [47:0] y_o
);

wire [48:0] block_0;
wire [47:0] sum_0;
wire carry_0;

assign block_0 =
    {1'b0, a_i[47:0]} +
    {1'b0, b_i[47:0]};

assign sum_0 =
    block_0[47:0];

assign carry_0 =
    block_0[48];

wire [47:0] sum;

assign sum = {
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

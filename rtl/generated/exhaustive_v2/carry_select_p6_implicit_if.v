module addpipe (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid_i,
    input  wire [7:0] a_i,
    input  wire [7:0] b_i,
    output reg        valid_o,
    output reg  [7:0] y_o
);


wire [6:0] lo;
wire [2:0] hi0;
wire [2:0] hi1;
wire [7:0] sum;

assign lo =
    {1'b0, a_i[5:0]}
    +
    {1'b0, b_i[5:0]};

assign hi0 =
    {1'b0, a_i[7:6]}
    +
    {1'b0, b_i[7:6]};

assign hi1 =
    {1'b0, a_i[7:6]}
    +
    {1'b0, b_i[7:6]}
    +
    1'b1;

assign sum[5:0] =
    lo[5:0];

assign sum[7:6] =
    lo[6]
    ? hi1[1:0]
    : hi0[1:0];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 8'd0;
    end else begin

        valid_o <= valid_i;
        if (valid_i)
            y_o <= sum;

    end
end

endmodule

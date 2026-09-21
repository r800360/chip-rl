module addpipe (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid_i,
    input  wire [7:0] a_i,
    input  wire [7:0] b_i,
    output reg        valid_o,
    output reg  [7:0] y_o
);


wire [7:0] lo;
wire [1:0] hi0;
wire [1:0] hi1;
wire [7:0] sum;

assign lo =
    {1'b0, a_i[6:0]}
    +
    {1'b0, b_i[6:0]};

assign hi0 =
    {1'b0, a_i[7:7]}
    +
    {1'b0, b_i[7:7]};

assign hi1 =
    {1'b0, a_i[7:7]}
    +
    {1'b0, b_i[7:7]}
    +
    1'b1;

assign sum[6:0] =
    lo[6:0];

assign sum[7:7] =
    lo[7]
    ? hi1[0:0]
    : hi0[0:0];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 8'd0;
    end else begin

        valid_o <= valid_i;
        if (valid_i)
            y_o <= sum;
        else
            y_o <= y_o;

    end
end

endmodule

module addpipe (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid_i,
    input  wire [7:0] a_i,
    input  wire [7:0] b_i,
    output reg        valid_o,
    output reg  [7:0] y_o
);


wire [1:0] lo;
wire [7:0] hi0;
wire [7:0] hi1;
wire [7:0] sum;

assign lo =
    {1'b0, a_i[0:0]}
    +
    {1'b0, b_i[0:0]};

assign hi0 =
    {1'b0, a_i[7:1]}
    +
    {1'b0, b_i[7:1]};

assign hi1 =
    {1'b0, a_i[7:1]}
    +
    {1'b0, b_i[7:1]}
    +
    1'b1;

assign sum[0:0] =
    lo[0:0];

assign sum[7:1] =
    lo[1]
    ? hi1[6:0]
    : hi0[6:0];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 8'd0;
    end else begin

        valid_o <= valid_i;
        case (valid_i)
            1'b1:    y_o <= sum;
            default: y_o <= y_o;
        endcase

    end
end

endmodule

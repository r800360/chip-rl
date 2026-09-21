module addpipe (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid_i,
    input  wire [7:0] a_i,
    input  wire [7:0] b_i,
    output reg        valid_o,
    output reg  [7:0] y_o
);


wire [5:0] lo;
wire [3:0] hi0;
wire [3:0] hi1;
wire [7:0] sum;

assign lo =
    {1'b0, a_i[4:0]}
    +
    {1'b0, b_i[4:0]};

assign hi0 =
    {1'b0, a_i[7:5]}
    +
    {1'b0, b_i[7:5]};

assign hi1 =
    {1'b0, a_i[7:5]}
    +
    {1'b0, b_i[7:5]}
    +
    1'b1;

assign sum[4:0] =
    lo[4:0];

assign sum[7:5] =
    lo[5]
    ? hi1[2:0]
    : hi0[2:0];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 8'd0;
    end else begin

        valid_o <= valid_i;
        y_o <= valid_i ? sum : y_o;

    end
end

endmodule

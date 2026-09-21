module addpipe (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid_i,
    input  wire [7:0] a_i,
    input  wire [7:0] b_i,
    output reg        valid_o,
    output reg  [7:0] y_o
);


wire [4:0] lo;

wire [4:0] hi0;
wire [4:0] hi1;

wire [3:0] hi_selected;
wire [7:0] sum;

assign lo =
    {1'b0, a_i[3:0]}
    +
    {1'b0, b_i[3:0]};

assign hi0 =
    {1'b0, a_i[7:4]}
    +
    {1'b0, b_i[7:4]};

assign hi1 =
    {1'b0, a_i[7:4]}
    +
    {1'b0, b_i[7:4]}
    +
    5'd1;

assign hi_selected =
    lo[4]
    ? hi1[3:0]
    : hi0[3:0];

assign sum = {
    hi_selected,
    lo[3:0]
};

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

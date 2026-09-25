module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
// explicit Brent-Kung lookahead + standard output stage (control experiment)
reg [31:0] pp, gg;
integer i, j;
always @* begin
    pp = a_i ^ b_i;
    gg = a_i & b_i;
    for (i = 1; i <= 5; i = i + 1)
        for (j = (1<<i) - 1; j < 32; j = j + (1<<i)) begin
            gg[j] = gg[j] | (pp[j] & gg[j - (1<<(i-1))]);
            pp[j] = pp[j] & pp[j - (1<<(i-1))];
        end
    for (i = 5; i > 0; i = i - 1)
        for (j = (1<<i) + (1<<(i-1)) - 1; j < 32; j = j + (1<<i)) begin
            gg[j] = gg[j] | (pp[j] & gg[j - (1<<(i-1))]);
            pp[j] = pp[j] & pp[j - (1<<(i-1))];
        end
end

wire [31:0] sum = (a_i ^ b_i) ^ {gg[30:0], 1'b0};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 32'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= sum;
    end
end
endmodule

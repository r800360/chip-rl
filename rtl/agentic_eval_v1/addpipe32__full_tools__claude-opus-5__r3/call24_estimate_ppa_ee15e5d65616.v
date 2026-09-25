module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
// explicit Brent-Kung lookahead (same as Yosys $lcu) + Shannon output stage
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

wire [31:0] x = a_i ^ b_i;
wire [31:0] c = {gg[30:0], 1'b0};
wire [31:0] t1 = rst_n ? (valid_i ? ~x : y_o) : 32'd0;
wire [31:0] t0 = rst_n ? (valid_i ?  x : y_o) : 32'd0;

always @(posedge clk) begin
    valid_o <= rst_n & valid_i;
    y_o     <= (c & t1) | (~c & t0);
end
endmodule

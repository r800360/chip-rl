module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
// explicit ripple carry chain + standard output stage
wire [31:0] p = a_i ^ b_i;
wire [31:0] g = a_i & b_i;
wire [32:0] c;
assign c[0] = 1'b0;
genvar i;
generate
  for (i = 0; i < 32; i = i + 1) begin : ch
    assign c[i+1] = g[i] | (p[i] & c[i]);
  end
endgenerate
wire [31:0] sum = p ^ c[31:0];

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

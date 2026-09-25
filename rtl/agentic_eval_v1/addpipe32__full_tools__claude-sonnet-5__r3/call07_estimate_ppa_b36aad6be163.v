module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

wire [32:0] c;
wire [31:0] sum;
assign c[0] = 1'b0;
genvar i;
generate
  for (i = 0; i < 32; i = i + 1) begin: fa
    assign sum[i] = a_i[i] ^ b_i[i] ^ c[i];
    assign c[i+1] = (a_i[i] & b_i[i]) | (c[i] & (a_i[i] ^ b_i[i]));
  end
endgenerate

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

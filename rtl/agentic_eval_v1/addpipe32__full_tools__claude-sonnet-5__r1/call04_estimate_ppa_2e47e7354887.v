module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 32'd0;
    end else if (valid_i) begin
        valid_o <= 1'b1;
        y_o     <= a_i + b_i;
    end else begin
        valid_o <= 1'b0;
    end
end

endmodule

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
    valid_o <= !rst_n ? 1'b0 : valid_i;
    y_o <= !rst_n ? 32'b0 : (valid_i ? a_i + b_i : y_o);
end

endmodule
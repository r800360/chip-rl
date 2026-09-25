module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

wire [31:0] sum = a_i + b_i;
wire        sel = rst_n & valid_i;
wire [31:0] hold_val = rst_n ? y_o : 32'd0;

always @(posedge clk) begin
    valid_o <= rst_n & valid_i;
    y_o     <= sel ? sum : hold_val;
end

endmodule

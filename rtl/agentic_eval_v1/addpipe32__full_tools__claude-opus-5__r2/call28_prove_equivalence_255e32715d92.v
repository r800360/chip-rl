module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
    wire [31:0] sum  = a_i + b_i;
    wire        en   = valid_i & rst_n;
    wire        hold = ~valid_i & rst_n;
always @(posedge clk) begin
    valid_o <= en;
    y_o     <= (sum & {32{en}}) | (y_o & {32{hold}});
end
endmodule
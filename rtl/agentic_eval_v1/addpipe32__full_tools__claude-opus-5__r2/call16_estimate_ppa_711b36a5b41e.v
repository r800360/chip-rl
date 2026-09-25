module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output wire [31:0] y_o
);
    // store inverted data so the last stage before the flop is an inverting
    // complex gate (AOI/OAI) instead of a MUX
    reg  [31:0] q;
    wire [31:0] sum = a_i + b_i;
    assign y_o = ~q;
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        q       <= 32'hFFFFFFFF;
    end else begin
        valid_o <= valid_i;
        if (valid_i) q <= ~sum;
    end
end
endmodule
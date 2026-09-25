module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

reg [0:0] y_next;

always @(*) begin
    if (valid_i)
        y_next = a_i < b_i;
    else
        y_next = y_o;
end

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        y_o <= y_next;
    end
end
endmodule

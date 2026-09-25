module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

reg [31:0] a_r, b_r;
reg valid_r;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
        a_r <= 32'd0;
        b_r <= 32'd0;
        valid_r <= 1'b0;
    end else begin
        a_r <= a_i;
        b_r <= b_i;
        valid_r <= valid_i;
        valid_o <= valid_r;
        if (valid_r)
            y_o <= (a_r < b_r);
    end
end
endmodule
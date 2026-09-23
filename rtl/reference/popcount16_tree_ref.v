// Width-16 independent behavioral oracle; b_i is reserved/ignored.
module popcount16_tree_ref (
    input wire clk, rst_n, valid_i,
    input wire [15:0] a_i, b_i,
    output reg valid_o,
    output reg [4:0] y_o
);
reg [4:0] computed;
integer i;
always @* begin
    computed = 5'd0;
    for (i = 0; i < 16; i = i + 1)
        computed = computed + a_i[i];
end
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 5'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= computed;
    end
end
endmodule

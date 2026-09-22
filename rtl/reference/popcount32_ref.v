module popcount32_ref (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
reg [5:0] computed;
integer i;
always @* begin
    computed = 6'd0;
    for (i = 0; i < 32; i = i + 1)
        computed = computed + a_i[i];
end
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= computed;
    end
end
endmodule

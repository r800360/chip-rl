module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

reg [5:0] chosen_0;
integer j;
always @(*) begin
    chosen_0 = 6'd0;
    for (j = 0; j < 32; j = j + 1) begin
        if (a_i[j])
            chosen_0 = j + 32;
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen_0;
    end
end
endmodule

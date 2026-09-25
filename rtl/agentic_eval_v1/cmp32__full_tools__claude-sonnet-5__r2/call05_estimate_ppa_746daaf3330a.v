module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire lt_0 = (a_i[31:0] < b_i[31:0]);
wire eq_0 = (a_i[31:0] == b_i[31:0]);

wire cmp_0 = lt_0;

reg [1:0] state;
always @(*) begin
    valid_o = state[1];
    y_o = state[0];
end

always @(posedge clk) begin
    if (!rst_n) begin
        state <= 2'b0;
    end else begin
        state[1] <= valid_i;
        if (valid_i)
            state[0] <= cmp_0;
    end
end
endmodule

module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
    integer k;
    reg [31:0] e;
    wire [31:0] p = ~(a_i ^ b_i);
    wire [31:0] g = ~a_i & b_i;
    always @* begin
        e[31] = 1'b1;
        for (k = 30; k >= 0; k = k - 1)
            e[k] = e[k+1] & p[k+1];
    end
    wire lt = |(g & e);
    wire s = valid_i & rst_n;
    wire h = ~valid_i & rst_n;
    always @(posedge clk) begin
        valid_o <= s;
        y_o <= (s & lt) | (h & y_o);
    end
endmodule
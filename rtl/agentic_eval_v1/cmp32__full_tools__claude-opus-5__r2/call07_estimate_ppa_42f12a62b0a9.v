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
    reg lo, hi;
    reg pp;
    always @* begin
        lo = 1'b0;
        for (k = 0; k < 16; k = k + 1) begin
            pp = ~(a_i[k] ^ b_i[k]);
            lo = pp ? lo : b_i[k];
        end
        hi = 1'b0;
        for (k = 16; k < 32; k = k + 1) begin
            pp = ~(a_i[k] ^ b_i[k]);
            hi = pp ? hi : b_i[k];
        end
    end
    wire eqh = (a_i[31:16] == b_i[31:16]);
    wire lt = hi | (eqh & lo);
    wire s = valid_i & rst_n;
    wire h = ~valid_i & rst_n;
    always @(posedge clk) begin
        valid_o <= s;
        y_o <= (s & lt) | (h & y_o);
    end
endmodule
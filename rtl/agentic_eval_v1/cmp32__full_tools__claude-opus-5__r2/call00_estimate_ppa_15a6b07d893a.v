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
    reg [31:0] g, p;
    reg lt;
    always @* begin
        for (k = 0; k < 32; k = k + 1) begin
            g[k] = ~a_i[k] & b_i[k];
            p[k] = ~(a_i[k] ^ b_i[k]);
        end
        for (k = 0; k < 16; k = k + 1) begin
            g[k] = g[2*k+1] | (p[2*k+1] & g[2*k]);
            p[k] = p[2*k+1] & p[2*k];
        end
        for (k = 0; k < 8; k = k + 1) begin
            g[k] = g[2*k+1] | (p[2*k+1] & g[2*k]);
            p[k] = p[2*k+1] & p[2*k];
        end
        for (k = 0; k < 4; k = k + 1) begin
            g[k] = g[2*k+1] | (p[2*k+1] & g[2*k]);
            p[k] = p[2*k+1] & p[2*k];
        end
        for (k = 0; k < 2; k = k + 1) begin
            g[k] = g[2*k+1] | (p[2*k+1] & g[2*k]);
            p[k] = p[2*k+1] & p[2*k];
        end
        lt = g[1] | (p[1] & g[0]);
    end

    wire s = valid_i & rst_n;
    wire h = ~valid_i & rst_n;

    always @(posedge clk) begin
        valid_o <= s;
        y_o <= (s & lt) | (h & y_o);
    end
endmodule
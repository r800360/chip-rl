module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
    integer j;
    reg [15:0] G, P;
    reg [15:0] E;
    reg lt;
    integer m;
    always @* begin
        for (j = 0; j < 16; j = j + 1) begin
            G[j] = (a_i[2*j +: 2] < b_i[2*j +: 2]);
            P[j] = (a_i[2*j +: 2] == b_i[2*j +: 2]);
        end
        E[15] = 1'b1;
        for (j = 14; j >= 0; j = j - 1)
            E[j] = E[j+1] & P[j+1];
        lt = |(G & E);
    end
    wire s = valid_i & rst_n;
    wire h = ~valid_i & rst_n;
    always @(posedge clk) begin
        valid_o <= s;
        y_o <= (s & lt) | (h & y_o);
    end
endmodule
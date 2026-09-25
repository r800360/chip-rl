module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);
    integer j, k;
    reg [7:0] G, P, E;
    reg t;
    reg lt;
    always @* begin
        for (j = 0; j < 8; j = j + 1) begin
            t = 1'b0;
            for (k = 0; k < 4; k = k + 1)
                t = (a_i[4*j+k] == b_i[4*j+k]) ? t : b_i[4*j+k];
            G[j] = t;
            P[j] = (a_i[4*j +: 4] == b_i[4*j +: 4]);
        end
        E[7] = 1'b1;
        for (j = 6; j >= 0; j = j - 1)
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
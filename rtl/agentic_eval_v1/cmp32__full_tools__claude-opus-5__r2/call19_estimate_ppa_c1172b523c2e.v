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
    reg [3:0] G, P;
    reg t;
    reg lt;
    always @* begin
        for (j = 0; j < 4; j = j + 1) begin
            t = 1'b0;
            for (k = 0; k < 8; k = k + 1)
                t = (a_i[8*j+k] == b_i[8*j+k]) ? t : b_i[8*j+k];
            G[j] = t;
            P[j] = (a_i[8*j +: 8] == b_i[8*j +: 8]);
        end
        lt = G[3]
           | (P[3] & G[2])
           | (P[3] & P[2] & G[1])
           | (P[3] & P[2] & P[1] & G[0]);
    end
    wire s = valid_i & rst_n;
    wire h = ~valid_i & rst_n;
    always @(posedge clk) begin
        valid_o <= s;
        y_o <= (s & lt) | (h & y_o);
    end
endmodule
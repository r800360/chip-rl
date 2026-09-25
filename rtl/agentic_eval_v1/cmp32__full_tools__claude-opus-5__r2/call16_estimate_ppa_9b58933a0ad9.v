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
    reg lt;
    always @* begin
        lt = 1'b0;
        for (j = 0; j < 16; j = j + 1)
            lt = (a_i[2*j +: 2] == b_i[2*j +: 2]) ? lt : (a_i[2*j +: 2] < b_i[2*j +: 2]);
    end
    wire s = valid_i & rst_n;
    wire h = ~valid_i & rst_n;
    always @(posedge clk) begin
        valid_o <= s;
        y_o <= (s & lt) | (h & y_o);
    end
endmodule
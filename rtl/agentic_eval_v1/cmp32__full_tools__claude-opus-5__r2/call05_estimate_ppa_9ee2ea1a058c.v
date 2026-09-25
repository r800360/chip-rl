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
    reg [3:0] cg, ce;
    reg t, e, pp;
    reg [1:0] dg, de;
    reg lt;
    always @* begin
        for (j = 0; j < 4; j = j + 1) begin
            t = 1'b0; e = 1'b1;
            for (k = 0; k < 8; k = k + 1) begin
                pp = ~(a_i[8*j+k] ^ b_i[8*j+k]);
                t = pp ? t : b_i[8*j+k];
                e = e & pp;
            end
            cg[j] = t; ce[j] = e;
        end
        for (j = 0; j < 2; j = j + 1) begin
            dg[j] = cg[2*j+1] | (ce[2*j+1] & cg[2*j]);
            de[j] = ce[2*j+1] & ce[2*j];
        end
        lt = dg[1] | (de[1] & dg[0]);
    end
    wire s = valid_i & rst_n;
    wire h = ~valid_i & rst_n;
    always @(posedge clk) begin
        valid_o <= s;
        y_o <= (s & lt) | (h & y_o);
    end
endmodule
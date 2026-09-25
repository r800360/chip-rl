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
    reg [31:0] L, nL, G, nG;
    reg tL, tnL, tG, tnG;
    reg lt;
    always @* begin
        for (k = 0; k < 32; k = k + 1) begin
            L[k]  = ~a_i[k] &  b_i[k];
            nL[k] =  a_i[k] | ~b_i[k];
            G[k]  =  a_i[k] & ~b_i[k];
            nG[k] = ~a_i[k] |  b_i[k];
        end
        for (k = 0; k < 16; k = k + 1) begin
            tL  = ~((nL[2*k+1] & nL[2*k]) |  G[2*k+1]);
            tnL = ~(( L[2*k+1] |  L[2*k]) & nG[2*k+1]);
            tG  = ~((nG[2*k+1] & nG[2*k]) |  L[2*k+1]);
            tnG = ~(( G[2*k+1] |  G[2*k]) & nL[2*k+1]);
            L[k] = tL; nL[k] = tnL; G[k] = tG; nG[k] = tnG;
        end
        for (k = 0; k < 8; k = k + 1) begin
            tL  = ~((nL[2*k+1] & nL[2*k]) |  G[2*k+1]);
            tnL = ~(( L[2*k+1] |  L[2*k]) & nG[2*k+1]);
            tG  = ~((nG[2*k+1] & nG[2*k]) |  L[2*k+1]);
            tnG = ~(( G[2*k+1] |  G[2*k]) & nL[2*k+1]);
            L[k] = tL; nL[k] = tnL; G[k] = tG; nG[k] = tnG;
        end
        for (k = 0; k < 4; k = k + 1) begin
            tL  = ~((nL[2*k+1] & nL[2*k]) |  G[2*k+1]);
            tnL = ~(( L[2*k+1] |  L[2*k]) & nG[2*k+1]);
            tG  = ~((nG[2*k+1] & nG[2*k]) |  L[2*k+1]);
            tnG = ~(( G[2*k+1] |  G[2*k]) & nL[2*k+1]);
            L[k] = tL; nL[k] = tnL; G[k] = tG; nG[k] = tnG;
        end
        for (k = 0; k < 2; k = k + 1) begin
            tL  = ~((nL[2*k+1] & nL[2*k]) |  G[2*k+1]);
            tnL = ~(( L[2*k+1] |  L[2*k]) & nG[2*k+1]);
            tG  = ~((nG[2*k+1] & nG[2*k]) |  L[2*k+1]);
            tnG = ~(( G[2*k+1] |  G[2*k]) & nL[2*k+1]);
            L[k] = tL; nL[k] = tnL; G[k] = tG; nG[k] = tnG;
        end
        lt = ~((nL[1] & nL[0]) | G[1]);
    end
    wire s = valid_i & rst_n;
    wire h = ~valid_i & rst_n;
    always @(posedge clk) begin
        valid_o <= s;
        y_o <= (s & lt) | (h & y_o);
    end
endmodule
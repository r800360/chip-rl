module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
    wire [3:0] grp, La, Lb, Lc;
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : GRP
            wire f3 = a_i[8*g+7] | a_i[8*g+6];
            wire f2 = a_i[8*g+5] | a_i[8*g+4];
            wire f1 = a_i[8*g+3] | a_i[8*g+2];
            wire f0 = a_i[8*g+1] | a_i[8*g+0];
            assign Lc[g]  = f3 | f2;
            assign grp[g] = f3 | f2 | f1 | f0;
            assign Lb[g]  = f3 | (f1 & ~f2);
            assign La[g]  = a_i[8*g+7]
                          | (a_i[8*g+5] & ~a_i[8*g+6])
                          | (a_i[8*g+3] & ~(a_i[8*g+6] | a_i[8*g+4]))
                          | (a_i[8*g+1] & ~(a_i[8*g+6] | a_i[8*g+4] | a_i[8*g+2]));
        end
    endgenerate

    wire m3 = ~grp[3];
    wire m2 = ~(grp[3] | grp[2]);
    wire m1 = ~(grp[3] | grp[2] | grp[1]);

    wire idx0 = La[3] | (m3 & La[2]) | (m2 & La[1]) | (m1 & La[0]);
    wire idx1 = Lb[3] | (m3 & Lb[2]) | (m2 & Lb[1]) | (m1 & Lb[0]);
    wire idx2 = Lc[3] | (m3 & Lc[2]) | (m2 & Lc[1]) | (m1 & Lc[0]);
    wire idx3 = grp[3] | (grp[1] & ~grp[2]);
    wire idx4 = grp[3] | grp[2];
    wire hit  = grp[3] | grp[2] | grp[1] | grp[0];

    wire [5:0] chosen = {hit, idx4, idx3, idx2, idx1, idx0};

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o <= 6'd0;
        end else begin
            valid_o <= valid_i;
            if (valid_i)
                y_o <= chosen;
        end
    end
endmodule
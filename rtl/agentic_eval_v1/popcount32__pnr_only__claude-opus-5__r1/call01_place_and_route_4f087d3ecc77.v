module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

    function [1:0] fa;
        input x;
        input y;
        input z;
        begin
            fa[0] = x ^ y ^ z;
            fa[1] = (x & y) | (x & z) | (y & z);
        end
    endfunction

    // stage 1 : 30 of the 32 bits -> 10 full adders
    wire [1:0] t0 = fa(a_i[0],  a_i[1],  a_i[2]);
    wire [1:0] t1 = fa(a_i[3],  a_i[4],  a_i[5]);
    wire [1:0] t2 = fa(a_i[6],  a_i[7],  a_i[8]);
    wire [1:0] t3 = fa(a_i[9],  a_i[10], a_i[11]);
    wire [1:0] t4 = fa(a_i[12], a_i[13], a_i[14]);
    wire [1:0] t5 = fa(a_i[15], a_i[16], a_i[17]);
    wire [1:0] t6 = fa(a_i[18], a_i[19], a_i[20]);
    wire [1:0] t7 = fa(a_i[21], a_i[22], a_i[23]);
    wire [1:0] t8 = fa(a_i[24], a_i[25], a_i[26]);
    wire [1:0] t9 = fa(a_i[27], a_i[28], a_i[29]);

    // stage 2 : weight-1 column (12 bits)
    wire [1:0] u0 = fa(t0[0], t1[0], t2[0]);
    wire [1:0] u1 = fa(t3[0], t4[0], t5[0]);
    wire [1:0] u2 = fa(t6[0], t7[0], t8[0]);
    wire [1:0] u3 = fa(t9[0], a_i[30], a_i[31]);
    // stage 2 : weight-2 column (10 bits, one left over)
    wire [1:0] u4 = fa(t0[1], t1[1], t2[1]);
    wire [1:0] u5 = fa(t3[1], t4[1], t5[1]);
    wire [1:0] u6 = fa(t6[1], t7[1], t8[1]);

    // remaining columns
    wire [1:0] p0 = u0[0] + u1[0];
    wire [1:0] p1 = u2[0] + u3[0];
    wire [2:0] P  = p0 + p1;                       // weight 1, max 4

    wire [1:0] qa = u0[1] + u1[1];
    wire [1:0] qb = u2[1] + u3[1];
    wire [1:0] qc = u4[0] + u5[0];
    wire [1:0] qd = u6[0] + t9[1];
    wire [2:0] qe = qa + qb;
    wire [2:0] qf = qc + qd;
    wire [3:0] Q  = qe + qf;                       // weight 2, max 8

    wire [1:0] r0 = u4[1] + u5[1];
    wire [1:0] R  = r0 + u6[1];                    // weight 4, max 3

    wire [4:0] W  = Q + {R, 1'b0};                 // max 14
    wire [5:0] total = P + {W, 1'b0};              // max 32

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= total;
    end
end
endmodule
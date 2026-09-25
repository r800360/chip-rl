module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
    wire [15:0] o2;
    wire [15:0] s1, s2, s3;
    wire [16:0] pr;
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : g2
            assign o2[i] = a_i[2*i] | a_i[2*i+1];
        end
        for (i = 0; i < 16; i = i + 1) begin : g1
            assign s1[i] = (i <= 14) ? (o2[i] | o2[i+1]) : o2[i];
        end
        for (i = 0; i < 16; i = i + 1) begin : gs2
            assign s2[i] = (i <= 13) ? (s1[i] | s1[i+2]) : s1[i];
        end
        for (i = 0; i < 16; i = i + 1) begin : gs3
            assign s3[i] = (i <= 11) ? (s2[i] | s2[i+4]) : s2[i];
        end
        for (i = 0; i < 16; i = i + 1) begin : gpr
            assign pr[i] = (i <= 7) ? (s3[i] | s3[i+8]) : s3[i];
        end
    endgenerate
    assign pr[16] = 1'b0;

    wire hit = pr[0];
    wire [4:0] idx;
    assign idx[4] = pr[8];
    assign idx[3] = pr[12] | (pr[4] & ~pr[8]);
    assign idx[2] = pr[14] | (pr[10] & ~pr[12]) | (pr[6] & ~pr[8]) | (pr[2] & ~pr[4]);
    assign idx[1] = pr[15] | (pr[13]&~pr[14]) | (pr[11]&~pr[12]) | (pr[9]&~pr[10])
                  | (pr[7]&~pr[8]) | (pr[5]&~pr[6]) | (pr[3]&~pr[4]) | (pr[1]&~pr[2]);
    wire [15:0] t0;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gt0
            assign t0[i] = a_i[2*i+1] & ~pr[i+1];
        end
    endgenerate
    assign idx[0] = |t0;

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o <= 6'd0;
        end else begin
            valid_o <= valid_i;
            if (valid_i) y_o <= {hit, idx};
        end
    end
endmodule
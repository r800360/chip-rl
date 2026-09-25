module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
    wire [31:0] o2x, Ax;
    wire [16:0] pr;
    wire [7:0]  c;
    wire [3:0]  La;
    wire [4:0]  idx;
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : L0
            assign o2x[i] = a_i[2*i] | a_i[2*i+1];
        end
        for (i = 16; i < 32; i = i + 1) begin : L0z
            assign o2x[i] = 1'b0;
        end
        for (i = 0; i < 8; i = i + 1) begin : LC
            assign c[i] = o2x[2*i] | o2x[2*i+1];
        end
        for (i = 0; i < 16; i = i + 1) begin : LA
            assign Ax[i] = o2x[i] | o2x[i+1] | o2x[i+2] | o2x[i+3];
        end
        for (i = 16; i < 32; i = i + 1) begin : LAz
            assign Ax[i] = 1'b0;
        end
        for (i = 0; i < 16; i = i + 1) begin : LP
            assign pr[i] = Ax[i] | Ax[i+4] | Ax[i+8] | Ax[i+12];
        end
        for (i = 0; i < 4; i = i + 1) begin : LL
            assign La[i] = a_i[8*i+7]
                         | (a_i[8*i+5] & ~a_i[8*i+6])
                         | (a_i[8*i+3] & ~(a_i[8*i+6] | a_i[8*i+4]))
                         | (a_i[8*i+1] & ~(a_i[8*i+6] | a_i[8*i+4] | a_i[8*i+2]));
        end
    endgenerate
    assign pr[16] = 1'b0;

    assign idx[4] = pr[8];
    assign idx[3] = pr[12] | (Ax[4] & ~pr[8]);
    assign idx[2] = c[7] | (c[5] & ~pr[12]) | (c[3] & ~pr[8]) | (c[1] & ~pr[4]);
    assign idx[1] = o2x[15] | (o2x[13] & ~pr[14]) | (o2x[11] & ~pr[12]) | (o2x[9] & ~pr[10])
                  | (o2x[7] & ~pr[8]) | (o2x[5] & ~pr[6]) | (o2x[3] & ~pr[4]) | (o2x[1] & ~pr[2]);
    assign idx[0] = La[3] | (La[2] & ~pr[12]) | (La[1] & ~pr[8]) | (La[0] & ~pr[4]);

    wire [5:0] chosen = {pr[0], idx};

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
module addpipe24 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [23:0] a_i,
    input  wire [23:0] b_i,
    output reg          valid_o,
    output reg  [23:0] y_o
);

    wire [23:0] p = a_i ^ b_i;
    wire [23:0] g = a_i & b_i;

    wire [23:0] sum;
    wire [5:0]  cin_block;
    wire [5:0]  cout_block;
    wire [5:0]  Pblk;

    assign cin_block[0] = 1'b0;

    genvar k;
    generate
        for (k = 0; k < 6; k = k + 1) begin : blk
            wire c0 = cin_block[k];
            wire c1 = g[4*k+0] | (p[4*k+0] & c0);
            wire c2 = g[4*k+1] | (p[4*k+1] & c1);
            wire c3 = g[4*k+2] | (p[4*k+2] & c2);
            wire c4 = g[4*k+3] | (p[4*k+3] & c3);

            assign Pblk[k]       = p[4*k+0] & p[4*k+1] & p[4*k+2] & p[4*k+3];
            assign cout_block[k] = Pblk[k] ? c0 : c4;

            assign sum[4*k+0] = p[4*k+0] ^ c0;
            assign sum[4*k+1] = p[4*k+1] ^ c1;
            assign sum[4*k+2] = p[4*k+2] ^ c2;
            assign sum[4*k+3] = p[4*k+3] ^ c3;
        end
    endgenerate

    generate
        for (k = 1; k < 6; k = k + 1) begin : chain
            assign cin_block[k] = cout_block[k-1];
        end
    endgenerate

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o     <= 24'd0;
        end else begin
            valid_o <= valid_i;
            if (valid_i)
                y_o <= sum;
        end
    end

endmodule

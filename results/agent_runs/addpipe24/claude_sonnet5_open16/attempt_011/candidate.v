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

    wire [23:0] c;
    assign c[0] = 1'b0;

    genvar i, k;
    generate
        for (i = 1; i < 24; i = i + 1) begin : cbit
            wire [i-1:0] terms;
            for (k = 0; k < i; k = k + 1) begin : kterm
                if (k == i-1) begin
                    assign terms[k] = g[k];
                end else begin
                    // g[k] AND (AND of p[m] for m = k+1 .. i-1)
                    assign terms[k] = g[k] & (&p[i-1:k+1]);
                end
            end
            assign c[i] = |terms;
        end
    endgenerate

    wire [23:0] sum;
    assign sum[0] = p[0];
    generate
        for (i = 1; i < 24; i = i + 1) begin : sumbit
            assign sum[i] = p[i] ^ c[i];
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

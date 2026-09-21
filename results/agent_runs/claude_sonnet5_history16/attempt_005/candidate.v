module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg          valid_o,
    output reg  [15:0] y_o
);

    wire [15:0] p, g;
    assign p = a_i ^ b_i;
    assign g = a_i & b_i;

    // c[i] = carry generated after adding bit i, with overall Cin = 0
    // c[i] = OR_{j=0..i} ( g[j] & AND_{k=j+1..i} p[k] )
    wire [14:0] c;

    genvar i, j;
    generate
        for (i = 0; i < 15; i = i + 1) begin : CROW
            wire [i:0] term;
            for (j = 0; j <= i; j = j + 1) begin : CCOL
                if (j == i) begin
                    assign term[j] = g[i];
                end else begin
                    assign term[j] = g[j] & (&p[i:j+1]);
                end
            end
            assign c[i] = |term;
        end
    endgenerate

    wire [15:0] sum;
    assign sum[0] = p[0];
    generate
        for (i = 1; i < 16; i = i + 1) begin : SUMBIT
            assign sum[i] = p[i] ^ c[i-1];
        end
    endgenerate

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o     <= 16'd0;
        end else begin
            valid_o <= valid_i;

            if (valid_i)
                y_o <= sum;
        end
    end

endmodule

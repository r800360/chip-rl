module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

    // ---- bit level generate / propagate (OR-form propagate: faster than XOR)
    wire [31:0] x0 = a_i ^ b_i;   // half sum, off the critical path
    wire [31:0] gg0 = a_i & b_i;
    wire [31:0] pp0 = a_i | b_i;

    // ---- Kogge-Stone carry tree
    wire [31:0] gg [0:5];
    wire [31:0] pp [0:5];
    assign gg[0] = gg0;
    assign pp[0] = pp0;

    genvar k, i;
    generate
        for (k = 0; k < 5; k = k + 1) begin : lvl
            for (i = 0; i < 32; i = i + 1) begin : bitpos
                if (i >= (1 << k)) begin : upd
                    assign gg[k+1][i] = gg[k][i] | (pp[k][i] & gg[k][i-(1<<k)]);
                    assign pp[k+1][i] = pp[k][i] & pp[k][i-(1<<k)];
                end else begin : cpy
                    assign gg[k+1][i] = gg[k][i];
                    assign pp[k+1][i] = pp[k][i];
                end
            end
        end
    endgenerate

    // ---- early control: reset folded into the two pre-computed data words
    wire        sel  = valid_i & rst_n;
    wire [31:0] hold = y_o & {32{rst_n}};
    wire [31:0] d0   = sel ?  x0 : hold;   // carry-in = 0
    wire [31:0] d1   = sel ? ~x0 : hold;   // carry-in = 1

    // ---- late carry selects directly at the flop input (single cell)
    wire [31:0] dn;
    assign dn[0] = d0[0];
    generate
        for (i = 1; i < 32; i = i + 1) begin : selb
            assign dn[i] = gg[5][i-1] ? d1[i] : d0[i];
        end
    endgenerate

    always @(posedge clk) begin
        valid_o <= valid_i & rst_n;
        y_o     <= dn;
    end

endmodule

module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

    wire [31:0] g = a_i & b_i;
    wire [31:0] t = a_i | b_i;
    wire [31:0] p = a_i ^ b_i;

    // Ling pseudo-carry:  H[i] = H0[i] | T0[i] & H[i-2]
    // H0[i] = g[i] | g[i-1]          (single AOI22 from a,b)
    // T0[i] = t[i-1] & t[i-2]        (single OAI22 from a,b)
    wire [31:0] H0 = g | (g << 1);
    wire [31:0] T0 = (t << 1) & (t << 2);

    wire [31:0] H1 = H0 | (T0 & (H0 << 2));
    wire [31:0] T1 = T0 & (T0 << 2);

    wire [31:0] H2 = H1 | (T1 & (H1 << 4));
    wire [31:0] T2 = T1 & (T1 << 4);

    wire [31:0] H3 = H2 | (T2 & (H2 << 8));
    wire [31:0] T3 = T2 & (T2 << 8);

    wire [31:0] H4 = H3 | (T3 & (H3 << 16));

    wire [31:0] Hs = {H4[30:0], 1'b0};   // H[i-1]
    wire [31:0] ts = {t[30:0], 1'b0};    // t[i-1]
    wire [31:0] q  = p ^ ts;             // sum bit when H[i-1] = 1

    // control: reset folded into early signals, late Hs sees one mux only
    wire        sel  = valid_i & rst_n;
    wire [31:0] hold = y_o & {32{rst_n}};
    wire [31:0] A    = sel ? q : hold;
    wire [31:0] B    = sel ? p : hold;
    wire [31:0] d    = (Hs & A) | (~Hs & B);

    always @(posedge clk) begin
        valid_o <= sel;
        y_o     <= d;
    end

endmodule

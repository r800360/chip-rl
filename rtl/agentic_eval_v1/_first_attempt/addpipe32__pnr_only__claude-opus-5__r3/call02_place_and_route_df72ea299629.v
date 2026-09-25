module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

// bit level signals
wire [31:0] g   = a_i & b_i;
wire [31:0] t   = a_i | b_i;
wire [31:0] p   = a_i ^ b_i;

wire [31:0] gm1 = {g[30:0], 1'b0};   // g[i-1]
wire [31:0] tm1 = {t[30:0], 1'b0};   // t[i-1]
wire [31:0] tm2 = {t[29:0], 2'b0};   // t[i-2]

// Ling pseudo-carry prefix, first level collapses to OR / AND of input pairs
wire [31:0] G1 = g   | {g[30:0], 1'b0};
wire [31:0] P1 = tm1 & tm2;

wire [31:0] G2 = G1 | (P1 & {G1[29:0],  2'b0});
wire [31:0] P2 = P1 & {P1[29:0],  2'b0};

wire [31:0] G3 = G2 | (P2 & {G2[27:0],  4'b0});
wire [31:0] P3 = P2 & {P2[27:0],  4'b0};

wire [31:0] G4 = G3 | (P3 & {G3[23:0],  8'b0});
wire [31:0] P4 = P3 & {P3[23:0],  8'b0};

wire [31:0] G5 = G4 | (P4 & {G4[15:0], 16'b0});

// only the odd prefix outputs are used: bits 2k and 2k+1 share select G5[2k-1]
wire [31:0] sel = {G5[29], G5[29], G5[27], G5[27], G5[25], G5[25], G5[23], G5[23],
                   G5[21], G5[21], G5[19], G5[19], G5[17], G5[17], G5[15], G5[15],
                   G5[13], G5[13], G5[11], G5[11], G5[ 9], G5[ 9], G5[ 7], G5[ 7],
                   G5[ 5], G5[ 5], G5[ 3], G5[ 3], G5[ 1], G5[ 1], 1'b0,  1'b0};

// data candidates, all derived from early signals
// even bit i : sum = p ^ (t[i-1] & H)          -> sel==0 : p           sel==1 : p ^ t[i-1]
// odd  bit i : sum = p ^ (g[i-1] | (P1 & H))   -> sel==0 : p ^ g[i-1]  sel==1 : p ^ (g[i-1]|P1)
wire [31:0] u0 = p ^ ( gm1            & 32'hAAAAAAAA);
wire [31:0] u1 = p ^ ((gm1 | P1)      & 32'hAAAAAAAA) ^ (tm1 & 32'h55555555);

wire [31:0] x0 = valid_i ? u0 : y_o;
wire [31:0] x1 = valid_i ? u1 : y_o;

// single late gate level selected by the prefix output
wire [31:0] ynext = (sel & x1) | (~sel & x0);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 32'd0;
    end else begin
        valid_o <= valid_i;
        y_o     <= ynext;
    end
end

endmodule

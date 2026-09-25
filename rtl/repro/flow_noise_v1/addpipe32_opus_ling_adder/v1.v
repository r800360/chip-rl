// variant: one leading comment
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

wire [31:0] tm1 = {t[30:0], 1'b0};   // t[i-1]
wire [31:0] tm2 = {t[29:0], 2'b0};   // t[i-2]

// Ling pseudo-carry prefix (Kogge-Stone), first level is a plain OR/AND
wire [31:0] G1 = g   | {g[30:0], 1'b0};
wire [31:0] P1 = tm1 & tm2;

wire [31:0] G2 = G1 | (P1 & {G1[29:0],  2'b0});
wire [31:0] P2 = P1 & {P1[29:0],  2'b0};

wire [31:0] G3 = G2 | (P2 & {G2[27:0],  4'b0});
wire [31:0] P3 = P2 & {P2[27:0],  4'b0};

wire [31:0] G4 = G3 | (P3 & {G3[23:0],  8'b0});
wire [31:0] P4 = P3 & {P3[23:0],  8'b0};

wire [31:0] G5 = G4 | (P4 & {G4[15:0], 16'b0});

// H[i] = pseudo carry, real carry c[i] = t[i-1] & H[i]
wire [31:0] H  = {G5[30:0], 1'b0};

// both mux data inputs are computed from early signals
wire [31:0] x0 = valid_i ? p           : y_o;
wire [31:0] x1 = valid_i ? (p ^ tm1)   : y_o;

// late signal H selects, one gate level only
wire [31:0] ynext = (H & x1) | (~H & x0);

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

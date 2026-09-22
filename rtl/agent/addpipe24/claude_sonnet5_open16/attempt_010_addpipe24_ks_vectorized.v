module addpipe24 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [23:0] a_i,
    input  wire [23:0] b_i,
    output reg          valid_o,
    output reg  [23:0] y_o
);

    // Bit-level generate/propagate
    wire [23:0] p0 = a_i ^ b_i;
    wire [23:0] g0 = a_i & b_i;

    // Vectorized Kogge-Stone prefix stages using shift+mask instead of
    // per-bit generate assigns, to let the synthesizer treat each stage
    // as a single word-level shift/AND/OR op and share logic more freely.

    localparam [23:0] MASK1  = 24'h000001;
    localparam [23:0] MASK2  = 24'h000003;
    localparam [23:0] MASK4  = 24'h00000F;
    localparam [23:0] MASK8  = 24'h0000FF;

    wire [23:0] g1, p1;
    assign g1 = g0 | (p0 & (g0 << 1));
    assign p1 = (p0 & (p0 << 1)) | (p0 & MASK1);

    wire [23:0] g2, p2;
    assign g2 = g1 | (p1 & (g1 << 2));
    assign p2 = (p1 & (p1 << 2)) | (p1 & MASK2);

    wire [23:0] g3, p3;
    assign g3 = g2 | (p2 & (g2 << 4));
    assign p3 = (p2 & (p2 << 4)) | (p2 & MASK4);

    wire [23:0] g4, p4;
    assign g4 = g3 | (p3 & (g3 << 8));
    assign p4 = (p3 & (p3 << 8)) | (p3 & MASK8);

    wire [23:0] g5;
    assign g5 = g4 | (p4 & (g4 << 16));
    // p5 not needed: this is the final prefix stage.

    // carry-in to bit i (i>=1) = cumulative generate through bit i-1;
    // carry-in to bit 0 = 0. Expressed as a single left shift.
    wire [23:0] c = {g5[22:0], 1'b0};

    wire [23:0] sum = p0 ^ c;

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

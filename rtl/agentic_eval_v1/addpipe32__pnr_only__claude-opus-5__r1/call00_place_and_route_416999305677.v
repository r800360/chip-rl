module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

    // ---- bit level propagate / generate ----
    wire [31:0] p0 = a_i ^ b_i;
    wire [31:0] g0 = a_i & b_i;

    // ---- Kogge-Stone prefix tree ----
    wire [31:0] g1 = g0 | (p0 & (g0 << 1));
    wire [31:0] p1 = p0 & (p0 << 1);

    wire [31:0] g2 = g1 | (p1 & (g1 << 2));
    wire [31:0] p2 = p1 & (p1 << 2);

    wire [31:0] g3 = g2 | (p2 & (g2 << 4));
    wire [31:0] p3 = p2 & (p2 << 4);

    wire [31:0] g4 = g3 | (p3 & (g3 << 8));
    wire [31:0] p4 = p3 & (p3 << 8);

    wire [31:0] g5 = g4 | (p4 & (g4 << 16));

    wire [31:0] carry = {g5[30:0], 1'b0};

    // ---- control: reset folded into enable / hold (off the adder path) ----
    wire        sel  = valid_i & rst_n;
    wire [31:0] hold = y_o & {32{rst_n}};

    // late signal "carry" selects between two early-computed vectors
    wire [31:0] ea = sel ? ~p0 : hold;   // carry == 1
    wire [31:0] eb = sel ?  p0 : hold;   // carry == 0
    wire [31:0] d  = (carry & ea) | (~carry & eb);

    always @(posedge clk) begin
        valid_o <= sel;
        y_o     <= d;
    end

endmodule

module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

// Kogge-Stone parallel prefix adder (no carry-in)
wire [31:0] g0 = a_i & b_i;
wire [31:0] p0 = a_i ^ b_i;

wire [31:0] g1 = g0 | (p0 & {g0[30:0], 1'b0});
wire [31:0] p1 = p0 & {p0[30:0], 1'b0};

wire [31:0] g2 = g1 | (p1 & {g1[29:0], 2'b0});
wire [31:0] p2 = p1 & {p1[29:0], 2'b0};

wire [31:0] g3 = g2 | (p2 & {g2[27:0], 4'b0});
wire [31:0] p3 = p2 & {p2[27:0], 4'b0};

wire [31:0] g4 = g3 | (p3 & {g3[23:0], 8'b0});
wire [31:0] p4 = p3 & {p3[23:0], 8'b0};

wire [31:0] g5 = g4 | (p4 & {g4[15:0], 16'b0});

wire [31:0] sum = p0 ^ {g5[30:0], 1'b0};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 32'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

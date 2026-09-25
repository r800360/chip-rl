module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

    wire [31:0] sum  = a_i + b_i;

    // early-arriving control: reset folded into select and hold value,
    // so the late "sum" signal sees only one MUX level before the flop.
    wire        sel  = valid_i & rst_n;
    wire [31:0] hold = y_o & {32{rst_n}};

    always @(posedge clk) begin
        valid_o <= valid_i & rst_n;
        y_o     <= sel ? sum : hold;
    end

endmodule

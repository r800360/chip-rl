module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

    wire [31:0] sum = a_i + b_i;

    // reset folded into the early control signals:
    //  - rst_n never sits behind the adder, it only gates the hold value
    //  - the late signal (sum) passes through a single 2:1 mux
    wire        sel  = valid_i & rst_n;
    wire [31:0] hold = y_o & {32{rst_n}};

    always @(posedge clk) begin
        valid_o <= sel;
        y_o     <= sel ? sum : hold;
    end

endmodule

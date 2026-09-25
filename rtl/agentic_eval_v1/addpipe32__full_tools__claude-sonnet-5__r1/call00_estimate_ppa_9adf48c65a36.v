module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

    // Carry-select adder split into two 16-bit halves to shorten the
    // critical carry-propagation path relative to a plain 32-bit ripple add.
    wire [16:0] sum_lo_ext = {1'b0, a_i[15:0]} + {1'b0, b_i[15:0]};
    wire        c16        = sum_lo_ext[16];
    wire [15:0] sum_lo     = sum_lo_ext[15:0];

    wire [15:0] sum_hi0 = a_i[31:16] + b_i[31:16];
    wire [15:0] sum_hi1 = a_i[31:16] + b_i[31:16] + 16'd1;
    wire [15:0] sum_hi  = c16 ? sum_hi1 : sum_hi0;

    wire [31:0] sum = {sum_hi, sum_lo};

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

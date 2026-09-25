module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

    wire [15:0] a_lo = a_i[15:0];
    wire [15:0] b_lo = b_i[15:0];
    wire [15:0] a_hi = a_i[31:16];
    wire [15:0] b_hi = b_i[31:16];

    wire [16:0] sum_lo  = {1'b0, a_lo} + {1'b0, b_lo};
    wire        carry_lo = sum_lo[16];

    wire [16:0] sum_hi0 = {1'b0, a_hi} + {1'b0, b_hi};
    wire [16:0] sum_hi1 = {1'b0, a_hi} + {1'b0, b_hi} + 17'd1;

    wire [15:0] sum_hi = carry_lo ? sum_hi1[15:0] : sum_hi0[15:0];

    wire [31:0] sum_full = {sum_hi, sum_lo[15:0]};

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o     <= 32'd0;
        end else begin
            valid_o <= valid_i;
            if (valid_i)
                y_o <= sum_full;
        end
    end

endmodule

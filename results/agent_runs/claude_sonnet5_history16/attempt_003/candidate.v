module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg          valid_o,
    output reg  [15:0] y_o
);

    // Lower 8-bit add, carry-out extracted
    wire [8:0] sum_lo9;
    assign sum_lo9 = {1'b0, a_i[7:0]} + {1'b0, b_i[7:0]};

    // Upper 8-bit add speculated for both possible incoming carries
    wire [7:0] sum_hi_c0;
    wire [7:0] sum_hi_c1;
    assign sum_hi_c0 = a_i[15:8] + b_i[15:8];
    assign sum_hi_c1 = a_i[15:8] + b_i[15:8] + 8'd1;

    // Select correct upper result using the lower carry-out
    wire [7:0] sum_hi_sel;
    assign sum_hi_sel = sum_lo9[8] ? sum_hi_c1 : sum_hi_c0;

    wire [15:0] sum_final;
    assign sum_final = {sum_hi_sel, sum_lo9[7:0]};

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            y_o     <= 16'd0;
        end else begin
            valid_o <= valid_i;

            if (valid_i)
                y_o <= sum_final;
        end
    end

endmodule

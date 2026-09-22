module addpipe24 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [23:0] a_i,
    input  wire [23:0] b_i,
    output reg          valid_o,
    output reg  [23:0] y_o
);

    // Lower 12-bit block: direct add, carry-in = 0
    wire [12:0] sum_low = {1'b0, a_i[11:0]} + {1'b0, b_i[11:0]};

    // Upper 12-bit block computed redundantly for both possible carry-ins
    wire [11:0] sum_up0 = a_i[23:12] + b_i[23:12];
    wire [11:0] sum_up1 = a_i[23:12] + b_i[23:12] + 12'd1;

    wire        cin_actual = sum_low[12];
    wire [11:0] upper_sel  = cin_actual ? sum_up1 : sum_up0;

    wire [23:0] sum = {upper_sel, sum_low[11:0]};

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

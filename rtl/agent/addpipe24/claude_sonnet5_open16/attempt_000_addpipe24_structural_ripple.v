module addpipe24 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [23:0] a_i,
    input  wire [23:0] b_i,
    output reg         valid_o,
    output reg  [23:0] y_o
);

    wire [23:0] sum;
    wire [24:0] carry;

    assign carry[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 24; i = i + 1) begin : fa_chain
            wire p = a_i[i] ^ b_i[i];
            assign sum[i]     = p ^ carry[i];
            assign carry[i+1] = (a_i[i] & b_i[i]) | (carry[i] & p);
        end
    endgenerate

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

module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg         valid_o,
    output reg  [15:0] y_o
);

wire [15:0] sum;
wire [16:0] carry;

assign carry[0] = 1'b0;

genvar i;
generate
    for (i = 0; i < 16; i = i + 1) begin : gen_ripple
        assign sum[i] =
            a_i[i] ^ b_i[i] ^ carry[i];

        assign carry[i + 1] =
            (a_i[i] & b_i[i]) |
            (a_i[i] & carry[i]) |
            (b_i[i] & carry[i]);
    end
endgenerate

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 16'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

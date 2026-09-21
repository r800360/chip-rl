module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg         valid_o,
    output reg  [15:0] y_o
);

wire [15:0] p;
wire [15:0] g;
wire [16:0] c;
wire [15:0] sum;

assign p = a_i ^ b_i;
assign g = a_i & b_i;

assign c[0] = 1'b0;

/* Block 0 */
assign c[1] = g[0] | (p[0] & c[0]);
assign c[2] = g[1] |
              (p[1] & g[0]) |
              (p[1] & p[0] & c[0]);

assign c[3] = g[2] |
              (p[2] & g[1]) |
              (p[2] & p[1] & g[0]) |
              (p[2] & p[1] & p[0] & c[0]);

assign c[4] = g[3] |
              (p[3] & g[2]) |
              (p[3] & p[2] & g[1]) |
              (p[3] & p[2] & p[1] & g[0]) |
              (p[3] & p[2] & p[1] & p[0] & c[0]);

/* Block 1 */
assign c[5] = g[4] | (p[4] & c[4]);

assign c[6] = g[5] |
              (p[5] & g[4]) |
              (p[5] & p[4] & c[4]);

assign c[7] = g[6] |
              (p[6] & g[5]) |
              (p[6] & p[5] & g[4]) |
              (p[6] & p[5] & p[4] & c[4]);

assign c[8] = g[7] |
              (p[7] & g[6]) |
              (p[7] & p[6] & g[5]) |
              (p[7] & p[6] & p[5] & g[4]) |
              (p[7] & p[6] & p[5] & p[4] & c[4]);

/* Block 2 */
assign c[9] = g[8] | (p[8] & c[8]);

assign c[10] = g[9] |
               (p[9] & g[8]) |
               (p[9] & p[8] & c[8]);

assign c[11] = g[10] |
               (p[10] & g[9]) |
               (p[10] & p[9] & g[8]) |
               (p[10] & p[9] & p[8] & c[8]);

assign c[12] = g[11] |
               (p[11] & g[10]) |
               (p[11] & p[10] & g[9]) |
               (p[11] & p[10] & p[9] & g[8]) |
               (p[11] & p[10] & p[9] & p[8] & c[8]);

/* Block 3 */
assign c[13] = g[12] | (p[12] & c[12]);

assign c[14] = g[13] |
               (p[13] & g[12]) |
               (p[13] & p[12] & c[12]);

assign c[15] = g[14] |
               (p[14] & g[13]) |
               (p[14] & p[13] & g[12]) |
               (p[14] & p[13] & p[12] & c[12]);

assign c[16] = g[15] |
               (p[15] & g[14]) |
               (p[15] & p[14] & g[13]) |
               (p[15] & p[14] & p[13] & g[12]) |
               (p[15] & p[14] & p[13] & p[12] & c[12]);

assign sum = p ^ c[15:0];

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

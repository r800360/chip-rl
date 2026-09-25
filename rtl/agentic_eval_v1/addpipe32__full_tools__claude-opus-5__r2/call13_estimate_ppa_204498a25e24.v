module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
    wire [12:0] lo = {1'b0, a_i[11:0]} + {1'b0, b_i[11:0]};
    wire [19:0] h0 = a_i[31:12] + b_i[31:12];
    wire [19:0] h1 = a_i[31:12] - (~b_i[31:12]);
    wire [31:0] sum = {(lo[12] ? h1 : h0), lo[11:0]};
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 32'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i) y_o <= sum;
    end
end
endmodule
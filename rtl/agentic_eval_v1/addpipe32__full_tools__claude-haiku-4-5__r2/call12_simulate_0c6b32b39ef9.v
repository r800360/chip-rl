module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

reg [31:0] sum;

always @(*) begin
    sum = a_i + b_i;
end

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 32'b0;
    end else begin
        valid_o <= valid_i;
        if (valid_i) begin
            y_o <= sum;
        end
    end
end

endmodule
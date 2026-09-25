module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
// Shannon expansion on the carry: late carry drives only the final 2:1 select
wire [31:0] p  = a_i ^ b_i;
wire [31:0] s  = a_i + b_i;
wire [31:0] c  = s ^ p;                 // carry into each bit
wire [31:0] t1 = rst_n ? (valid_i ? ~p : y_o) : 32'd0;
wire [31:0] t0 = rst_n ? (valid_i ?  p : y_o) : 32'd0;

always @(posedge clk) begin
    valid_o <= rst_n & valid_i;
    y_o     <= (c & t1) | (~c & t0);
end
endmodule

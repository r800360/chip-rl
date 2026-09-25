module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
// OR-propagate Kogge-Stone (cheap first level) + Shannon final stage
wire [31:0] g0 = a_i & b_i;
wire [31:0] r0 = a_i | b_i;          // propagate (OR form)
wire [31:0] x  = r0 & ~g0;           // a^b, off critical path

wire [191:0] gv;
wire [191:0] pv;
assign gv[31:0] = g0;
assign pv[31:0] = r0;

genvar l, i;
generate
  for (l = 1; l <= 5; l = l + 1) begin : lev
    for (i = 0; i < 32; i = i + 1) begin : bslc
      if (i >= (1 << (l-1))) begin : upd
        assign gv[l*32+i] = gv[(l-1)*32+i] | (pv[(l-1)*32+i] & gv[(l-1)*32+i-(1<<(l-1))]);
        assign pv[l*32+i] = pv[(l-1)*32+i] & pv[(l-1)*32+i-(1<<(l-1))];
      end else begin : pass
        assign gv[l*32+i] = gv[(l-1)*32+i];
        assign pv[l*32+i] = pv[(l-1)*32+i];
      end
    end
  end
endgenerate

wire [31:0] c  = {gv[190:160], 1'b0};
wire [31:0] t1 = rst_n ? (valid_i ? ~x : y_o) : 32'd0;
wire [31:0] t0 = rst_n ? (valid_i ?  x : y_o) : 32'd0;

always @(posedge clk) begin
    valid_o <= rst_n & valid_i;
    y_o     <= (c & t1) | (~c & t0);
end
endmodule

module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
// OR-propagate, 2-bit leaf groups, Sklansky prefix over 16, Shannon output
wire [31:0] g = a_i & b_i;
wire [31:0] r = a_i | b_i;
wire [31:0] x = r & ~g;

wire [15:0] PG, PP;
genvar j, l;
generate
  for (j = 0; j < 16; j = j + 1) begin : pr
    assign PG[j] = g[2*j+1] | (r[2*j+1] & g[2*j]);
    assign PP[j] = r[2*j+1] & r[2*j];
  end
endgenerate

wire [79:0] gv, pv;
assign gv[15:0] = PG;
assign pv[15:0] = PP;
generate
  for (l = 1; l <= 4; l = l + 1) begin : lev
    for (j = 0; j < 16; j = j + 1) begin : nd
      if (((j >> (l-1)) & 1) == 1) begin : upd
        localparam integer BASE = ((j >> (l-1)) << (l-1)) - 1;
        assign gv[l*16+j] = gv[(l-1)*16+j] | (pv[(l-1)*16+j] & gv[(l-1)*16+BASE]);
        assign pv[l*16+j] = pv[(l-1)*16+j] & pv[(l-1)*16+BASE];
      end else begin : pass
        assign gv[l*16+j] = gv[(l-1)*16+j];
        assign pv[l*16+j] = pv[(l-1)*16+j];
      end
    end
  end
endgenerate

wire [15:0] CG = gv[79:64];

wire [31:0] sel, u0, u1;
assign sel[0] = 1'b0;
assign u0[0]  = x[0];
assign u1[0]  = x[0];
assign sel[1] = 1'b0;
assign u0[1]  = x[1] ^ g[0];
assign u1[1]  = x[1] ^ g[0];
generate
  for (j = 1; j < 16; j = j + 1) begin : fin
    assign sel[2*j]   = CG[j-1];
    assign u0[2*j]    = x[2*j];
    assign u1[2*j]    = ~x[2*j];
    assign sel[2*j+1] = CG[j-1];
    assign u0[2*j+1]  = x[2*j+1] ^ g[2*j];
    assign u1[2*j+1]  = x[2*j+1] ^ r[2*j];
  end
endgenerate

wire [31:0] t1 = rst_n ? (valid_i ? u1 : y_o) : 32'd0;
wire [31:0] t0 = rst_n ? (valid_i ? u0 : y_o) : 32'd0;

always @(posedge clk) begin
    valid_o <= rst_n & valid_i;
    y_o     <= (sel & t1) | (~sel & t0);
end
endmodule

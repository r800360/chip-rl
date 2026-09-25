module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
    wire [31:0] Gv [0:5];
    wire [31:0] Pv [0:5];
    assign Gv[0] = a_i & b_i;
    assign Pv[0] = a_i ^ b_i;
    genvar k, i;
    generate
      for (k = 0; k < 5; k = k + 1) begin : LK
        for (i = 0; i < 32; i = i + 1) begin : LI
          localparam integer blk  = (1 << (k+1));
          localparam integer base = (i / blk) * blk;
          localparam integer mid  = base + (blk >> 1);
          if (i >= mid) begin : up
            assign Gv[k+1][i] = Gv[k][i] | (Pv[k][i] & Gv[k][mid-1]);
            assign Pv[k+1][i] = Pv[k][i] & Pv[k][mid-1];
          end else begin : lo
            assign Gv[k+1][i] = Gv[k][i];
            assign Pv[k+1][i] = Pv[k][i];
          end
        end
      end
    endgenerate
    wire [31:0] sum  = Pv[0] ^ {Gv[5][30:0], 1'b0};
    wire        en   = valid_i & rst_n;
    wire        hold = ~valid_i & rst_n;
always @(posedge clk) begin
    valid_o <= en;
    y_o     <= (sum & {32{en}}) | (y_o & {32{hold}});
end
endmodule
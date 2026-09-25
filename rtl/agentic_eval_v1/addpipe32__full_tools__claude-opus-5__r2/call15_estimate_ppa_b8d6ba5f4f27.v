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
    wire [31:0] Tv [0:5];
    assign Gv[0] = a_i & b_i;
    assign Tv[0] = a_i | b_i;
    genvar k, i;
    generate
      for (k = 0; k < 5; k = k + 1) begin : LK
        for (i = 0; i < 32; i = i + 1) begin : LI
          localparam integer blk  = (1 << (k+1));
          localparam integer base = (i / blk) * blk;
          localparam integer mid  = base + (blk >> 1);
          if (i >= mid) begin : up
            assign Gv[k+1][i] = Gv[k][i] | (Tv[k][i] & Gv[k][mid-1]);
            assign Tv[k+1][i] = Tv[k][i] & Tv[k][mid-1];
          end else begin : lo
            assign Gv[k+1][i] = Gv[k][i];
            assign Tv[k+1][i] = Tv[k][i];
          end
        end
      end
    endgenerate
    wire [31:0] sum = (a_i ^ b_i) ^ {Gv[5][30:0], 1'b0};
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
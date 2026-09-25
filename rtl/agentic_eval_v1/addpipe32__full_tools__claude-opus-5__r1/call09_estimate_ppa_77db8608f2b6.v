module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
    // Han-Carlson prefix adder
    wire [31:0] p0 = a_i ^ b_i;
    wire [31:0] g0 = a_i & b_i;

    // stage 1: pair up (odd positions hold 2-bit groups)
    wire [31:0] g1, p1;
    wire [31:0] g2, p2, g3, p3, g4, p4, g5, p5, g6;
    genvar i;
    generate
      for (i = 0; i < 32; i = i + 1) begin : s1
        if (i[0] == 1'b1) begin : od
          assign g1[i] = g0[i] | (p0[i] & g0[i-1]);
          assign p1[i] = p0[i] & p0[i-1];
        end else begin : ev
          assign g1[i] = g0[i];
          assign p1[i] = p0[i];
        end
      end
      // KS over odd positions, distances 2,4,8,16
      for (i = 0; i < 32; i = i + 1) begin : s2
        if (i[0] == 1'b1 && i >= 3) begin : od
          assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
          assign p2[i] = p1[i] & p1[i-2];
        end else begin : ev
          assign g2[i] = g1[i];
          assign p2[i] = p1[i];
        end
      end
      for (i = 0; i < 32; i = i + 1) begin : s3
        if (i[0] == 1'b1 && i >= 5) begin : od
          assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
          assign p3[i] = p2[i] & p2[i-4];
        end else begin : ev
          assign g3[i] = g2[i];
          assign p3[i] = p2[i];
        end
      end
      for (i = 0; i < 32; i = i + 1) begin : s4
        if (i[0] == 1'b1 && i >= 9) begin : od
          assign g4[i] = g3[i] | (p3[i] & g3[i-8]);
          assign p4[i] = p3[i] & p3[i-8];
        end else begin : ev
          assign g4[i] = g3[i];
          assign p4[i] = p3[i];
        end
      end
      for (i = 0; i < 32; i = i + 1) begin : s5
        if (i[0] == 1'b1 && i >= 17) begin : od
          assign g5[i] = g4[i] | (p4[i] & g4[i-16]);
          assign p5[i] = p4[i] & p4[i-16];
        end else begin : ev
          assign g5[i] = g4[i];
          assign p5[i] = p4[i];
        end
      end
      // final: even positions pick up from odd neighbour
      for (i = 0; i < 32; i = i + 1) begin : s6
        if (i[0] == 1'b0 && i >= 1) begin : ev
          assign g6[i] = g0[i] | (p0[i] & g5[i-1]);
        end else begin : od
          assign g6[i] = g5[i];
        end
      end
    endgenerate

    wire [31:0] sum = p0 ^ {g6[30:0], 1'b0};
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 32'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= sum;
    end
end
endmodule

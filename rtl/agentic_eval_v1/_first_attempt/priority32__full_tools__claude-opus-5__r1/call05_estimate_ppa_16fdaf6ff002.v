module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// radix-4 leaves: 8 groups of 4 bits
wire [7:0] vA;
wire [15:0] pA; // 2 bits each
genvar g;
generate
for (g = 0; g < 8; g = g + 1) begin : L0
  assign vA[g]        = |a_i[4*g +: 4];
  assign pA[2*g+1]    = a_i[4*g+3] | a_i[4*g+2];
  assign pA[2*g+0]    = a_i[4*g+3] | (a_i[4*g+1] & ~a_i[4*g+2]);
end
endgenerate

// level B: 2 groups of 16 bits (4 leaves each)
wire [1:0] vB;
wire [7:0] qB; // 4 bits each
generate
for (g = 0; g < 2; g = g + 1) begin : L1
  wire s3 = vA[4*g+3];
  wire s2 = ~vA[4*g+3] & vA[4*g+2];
  wire s1 = ~vA[4*g+3] & ~vA[4*g+2] & vA[4*g+1];
  wire s0 = ~vA[4*g+3] & ~vA[4*g+2] & ~vA[4*g+1];
  assign vB[g]      = |a_i[16*g +: 16];
  assign qB[4*g+3]  = vA[4*g+3] | vA[4*g+2];
  assign qB[4*g+2]  = vA[4*g+3] | (vA[4*g+1] & ~vA[4*g+2]);
  assign qB[4*g+1]  = (s3 & pA[2*(4*g+3)+1]) | (s2 & pA[2*(4*g+2)+1]) |
                      (s1 & pA[2*(4*g+1)+1]) | (s0 & pA[2*(4*g+0)+1]);
  assign qB[4*g+0]  = (s3 & pA[2*(4*g+3)+0]) | (s2 & pA[2*(4*g+2)+0]) |
                      (s1 & pA[2*(4*g+1)+0]) | (s0 & pA[2*(4*g+0)+0]);
end
endgenerate

wire hit = |a_i;
wire [3:0] low = vB[1] ? qB[7:4] : qB[3:0];
wire [5:0] chosen_0 = {hit, vB[1], low};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen_0;
    end
end
endmodule

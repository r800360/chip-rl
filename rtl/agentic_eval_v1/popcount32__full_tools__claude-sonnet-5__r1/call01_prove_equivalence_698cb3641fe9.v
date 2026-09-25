module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Level 0: pairs of bits -> 2-bit sums (16 outputs)
wire [1:0] l0 [0:15];
genvar i;
generate
  for (i=0;i<16;i=i+1) begin: L0
    assign l0[i] = a_i[2*i] + a_i[2*i+1];
  end
endgenerate

// Level1: pairs of l0 -> 3-bit sums (8 outputs)
wire [2:0] l1 [0:7];
generate
  for (i=0;i<8;i=i+1) begin: L1
    assign l1[i] = l0[2*i] + l0[2*i+1];
  end
endgenerate

// Level2: pairs of l1 -> 4-bit sums (4 outputs)
wire [3:0] l2 [0:3];
generate
  for (i=0;i<4;i=i+1) begin: L2
    assign l2[i] = l1[2*i] + l1[2*i+1];
  end
endgenerate

// Level3: pairs of l2 -> 5-bit sums (2 outputs)
wire [4:0] l3 [0:1];
generate
  for (i=0;i<2;i=i+1) begin: L3
    assign l3[i] = l2[2*i] + l2[2*i+1];
  end
endgenerate

// Level4: final 6-bit sum
wire [5:0] total_0 = l3[0] + l3[1];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= total_0;
    end
end
endmodule

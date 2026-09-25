module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

// bit-level less-than and equal (index 31 = MSB)
wire [31:0] eq_b = ~(a_i ^ b_i);
wire [31:0] lt_b = (~a_i) & b_i;

// Level1: combine (31,30),(29,28),...,(1,0) -> 16 entries, index0 = most significant
wire [15:0] eq_l1, lt_l1;
genvar i;
generate
  for (i=0;i<16;i=i+1) begin : L1
    localparam integer HI = 31-2*i;
    localparam integer LO = HI-1;
    assign eq_l1[i] = eq_b[HI] & eq_b[LO];
    assign lt_l1[i] = lt_b[HI] | (eq_b[HI] & lt_b[LO]);
  end
endgenerate

// Level2: combine adjacent pairs of L1 entries -> 8 entries
wire [7:0] eq_l2, lt_l2;
generate
  for (i=0;i<8;i=i+1) begin : L2
    localparam integer HI = 2*i;
    localparam integer LO = HI+1;
    assign eq_l2[i] = eq_l1[HI] & eq_l1[LO];
    assign lt_l2[i] = lt_l1[HI] | (eq_l1[HI] & lt_l1[LO]);
  end
endgenerate

// Level3: -> 4 entries
wire [3:0] eq_l3, lt_l3;
generate
  for (i=0;i<4;i=i+1) begin : L3
    localparam integer HI = 2*i;
    localparam integer LO = HI+1;
    assign eq_l3[i] = eq_l2[HI] & eq_l2[LO];
    assign lt_l3[i] = lt_l2[HI] | (eq_l2[HI] & lt_l2[LO]);
  end
endgenerate

// Level4: -> 2 entries
wire [1:0] eq_l4, lt_l4;
generate
  for (i=0;i<2;i=i+1) begin : L4
    localparam integer HI = 2*i;
    localparam integer LO = HI+1;
    assign eq_l4[i] = eq_l3[HI] & eq_l3[LO];
    assign lt_l4[i] = lt_l3[HI] | (eq_l3[HI] & lt_l3[LO]);
  end
endgenerate

// Level5: -> 1 entry (final)
wire lt_l5;
assign lt_l5 = lt_l4[0] | (eq_l4[0] & lt_l4[1]);

wire cmp_0 = lt_l5;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= cmp_0;
    end
end
endmodule

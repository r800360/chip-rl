module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

// nibble-level (4-bit) less-than / equal, 8 nibbles, index0 = MSB nibble
wire [7:0] eq_n, lt_n;
genvar i;
generate
  for (i=0;i<8;i=i+1) begin : NIB
    localparam integer HI = 31-4*i;
    localparam integer LO = HI-3;
    assign eq_n[i] = (a_i[HI:LO] == b_i[HI:LO]);
    assign lt_n[i] = (a_i[HI:LO] < b_i[HI:LO]);
  end
endgenerate

// combine tree: 8 -> 4 -> 2 -> 1
wire [3:0] eq_m1, lt_m1;
generate
  for (i=0;i<4;i=i+1) begin : M1
    localparam integer HI = 2*i;
    localparam integer LO = HI+1;
    assign eq_m1[i] = eq_n[HI] & eq_n[LO];
    assign lt_m1[i] = lt_n[HI] | (eq_n[HI] & lt_n[LO]);
  end
endgenerate

wire [1:0] eq_m2, lt_m2;
generate
  for (i=0;i<2;i=i+1) begin : M2
    localparam integer HI = 2*i;
    localparam integer LO = HI+1;
    assign eq_m2[i] = eq_m1[HI] & eq_m1[LO];
    assign lt_m2[i] = lt_m1[HI] | (eq_m1[HI] & lt_m1[LO]);
  end
endgenerate

wire lt_final = lt_m2[0] | (eq_m2[0] & lt_m2[1]);

wire cmp_0 = lt_final;

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

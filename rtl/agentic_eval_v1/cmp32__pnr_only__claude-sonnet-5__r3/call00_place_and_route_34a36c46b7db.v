module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

// Level 0: bitwise lt/eq
wire [31:0] lt0 = ~a_i & b_i;
wire [31:0] eq0 = ~(a_i ^ b_i);

// Level 1: combine pairs of 2 bits -> 16 groups
wire [15:0] lt1, eq1;
genvar i;
generate
  for (i = 0; i < 16; i = i + 1) begin : L1
    assign lt1[i] = lt0[2*i+1] | (eq0[2*i+1] & lt0[2*i]);
    assign eq1[i] = eq0[2*i+1] & eq0[2*i];
  end
endgenerate

// Level 2: combine into 8 groups of 4 bits
wire [7:0] lt2, eq2;
generate
  for (i = 0; i < 8; i = i + 1) begin : L2
    assign lt2[i] = lt1[2*i+1] | (eq1[2*i+1] & lt1[2*i]);
    assign eq2[i] = eq1[2*i+1] & eq1[2*i];
  end
endgenerate

// Level 3: combine into 4 groups of 8 bits
wire [3:0] lt3, eq3;
generate
  for (i = 0; i < 4; i = i + 1) begin : L3
    assign lt3[i] = lt2[2*i+1] | (eq2[2*i+1] & lt2[2*i]);
    assign eq3[i] = eq2[2*i+1] & eq2[2*i];
  end
endgenerate

// Level 4: combine into 2 groups of 16 bits
wire [1:0] lt4, eq4;
generate
  for (i = 0; i < 2; i = i + 1) begin : L4
    assign lt4[i] = lt3[2*i+1] | (eq3[2*i+1] & lt3[2*i]);
    assign eq4[i] = eq3[2*i+1] & eq3[2*i];
  end
endgenerate

// Level 5: final combine into 1 group of 32 bits
wire lt5 = lt4[1] | (eq4[1] & lt4[0]);

wire cmp_0 = lt5;

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

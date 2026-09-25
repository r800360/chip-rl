module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire lt0 [0:31];
wire eq0 [0:31];
genvar k;
generate
  for (k=0;k<32;k=k+1) begin : L0
    assign lt0[k] = (~a_i[31-k]) & b_i[31-k];
    assign eq0[k] = ~(a_i[31-k] ^ b_i[31-k]);
  end
endgenerate

wire lt1 [0:15];
wire eq1 [0:15];
generate
  for (k=0;k<16;k=k+1) begin : L1
    assign lt1[k] = lt0[2*k] | (eq0[2*k] & lt0[2*k+1]);
    assign eq1[k] = eq0[2*k] & eq0[2*k+1];
  end
endgenerate

wire lt2 [0:7];
wire eq2 [0:7];
generate
  for (k=0;k<8;k=k+1) begin : L2
    assign lt2[k] = lt1[2*k] | (eq1[2*k] & lt1[2*k+1]);
    assign eq2[k] = eq1[2*k] & eq1[2*k+1];
  end
endgenerate

wire lt3 [0:3];
wire eq3 [0:3];
generate
  for (k=0;k<4;k=k+1) begin : L3
    assign lt3[k] = lt2[2*k] | (eq2[2*k] & lt2[2*k+1]);
    assign eq3[k] = eq2[2*k] & eq2[2*k+1];
  end
endgenerate

wire lt4 [0:1];
wire eq4 [0:1];
generate
  for (k=0;k<2;k=k+1) begin : L4
    assign lt4[k] = lt3[2*k] | (eq3[2*k] & lt3[2*k+1]);
    assign eq4[k] = eq3[2*k] & eq3[2*k+1];
  end
endgenerate

wire cmp_0 = lt4[0] | (eq4[0] & lt4[1]);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'b0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= cmp_0;
    end
end
endmodule

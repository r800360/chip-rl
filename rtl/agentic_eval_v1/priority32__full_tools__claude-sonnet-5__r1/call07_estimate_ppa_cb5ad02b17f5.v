module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire [5:0] c0 [0:31];
genvar i;
generate
  for (i=0;i<32;i=i+1) begin: L0
    assign c0[i] = a_i[i] ? (i+32) : 6'd0;
  end
endgenerate

wire [5:0] c1 [0:15];
generate
  for (i=0;i<16;i=i+1) begin: L1
    assign c1[i] = (c0[2*i+1] != 6'd0) ? c0[2*i+1] : c0[2*i];
  end
endgenerate

wire [5:0] c2 [0:7];
generate
  for (i=0;i<8;i=i+1) begin: L2
    assign c2[i] = (c1[2*i+1] != 6'd0) ? c1[2*i+1] : c1[2*i];
  end
endgenerate

wire [5:0] c3 [0:3];
generate
  for (i=0;i<4;i=i+1) begin: L3
    assign c3[i] = (c2[2*i+1] != 6'd0) ? c2[2*i+1] : c2[2*i];
  end
endgenerate

wire [5:0] c4 [0:1];
generate
  for (i=0;i<2;i=i+1) begin: L4
    assign c4[i] = (c3[2*i+1] != 6'd0) ? c3[2*i+1] : c3[2*i];
  end
endgenerate

wire [5:0] chosen_0 = (c4[1] != 6'd0) ? c4[1] : c4[0];

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

// Independent behavioral reference: sixteen unsigned 8-bit inputs.
module lanesum16x8_tree_ref (
  input wire clk, rst_n, valid_i,
  input wire [63:0] a_i, b_i,
  output reg valid_o,
  output reg [11:0] y_o
);
reg [11:0] computed;
integer i;
always @* begin
  computed = 12'd0;
  for (i = 0; i < 8; i = i + 1) begin
    computed = computed + a_i[(i*8) +: 8];
    computed = computed + b_i[(i*8) +: 8];
  end
end
always @(posedge clk) begin
  if (!rst_n) begin
    valid_o <= 1'b0;
    y_o <= 12'd0;
  end else begin
    valid_o <= valid_i;
    if (valid_i) y_o <= computed;
  end
end
endmodule

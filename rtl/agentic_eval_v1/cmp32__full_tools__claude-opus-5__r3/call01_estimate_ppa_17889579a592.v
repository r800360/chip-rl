module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire [31:0] l0 = ~a_i & b_i;
wire [31:0] e0 = ~(a_i ^ b_i);

wire [7:0] lg, eg;
wire [1:0] lh, eh;
wire lt;

genvar i;
generate
  for (i = 0; i < 8; i = i + 1) begin : G
    assign lg[i] = l0[4*i+3] | (e0[4*i+3] & l0[4*i+2])
                 | (e0[4*i+3] & e0[4*i+2] & l0[4*i+1])
                 | (e0[4*i+3] & e0[4*i+2] & e0[4*i+1] & l0[4*i]);
    assign eg[i] = e0[4*i+3] & e0[4*i+2] & e0[4*i+1] & e0[4*i];
  end
  for (i = 0; i < 2; i = i + 1) begin : H
    assign lh[i] = lg[4*i+3] | (eg[4*i+3] & lg[4*i+2])
                 | (eg[4*i+3] & eg[4*i+2] & lg[4*i+1])
                 | (eg[4*i+3] & eg[4*i+2] & eg[4*i+1] & lg[4*i]);
    assign eh[i] = eg[4*i+3] & eg[4*i+2] & eg[4*i+1] & eg[4*i];
  end
endgenerate
assign lt = lh[1] | (eh[1] & lh[0]);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= lt;
    end
end
endmodule
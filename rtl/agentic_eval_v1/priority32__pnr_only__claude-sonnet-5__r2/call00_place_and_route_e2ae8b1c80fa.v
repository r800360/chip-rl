module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Balanced-tree leading-one detector.
// At each level, priority is given to the higher-indexed (upper) half.
wire hit_l0 [0:31];
wire hit_l1 [0:15];
wire hit_l2 [0:7];
wire hit_l3 [0:3];
wire hit_l4 [0:1];
wire hit_l5;

wire [0:0] idx_l1 [0:15];
wire [1:0] idx_l2 [0:7];
wire [2:0] idx_l3 [0:3];
wire [3:0] idx_l4 [0:1];
wire [4:0] idx_l5;

genvar i;
generate
  for (i = 0; i < 32; i = i + 1) begin: g0
    assign hit_l0[i] = a_i[i];
  end
  for (i = 0; i < 16; i = i + 1) begin: g1
    assign hit_l1[i] = hit_l0[2*i+1] | hit_l0[2*i];
    assign idx_l1[i] = hit_l0[2*i+1] ? 1'b1 : 1'b0;
  end
  for (i = 0; i < 8; i = i + 1) begin: g2
    assign hit_l2[i] = hit_l1[2*i+1] | hit_l1[2*i];
    assign idx_l2[i] = hit_l1[2*i+1] ? {1'b1, idx_l1[2*i+1]} : {1'b0, idx_l1[2*i]};
  end
  for (i = 0; i < 4; i = i + 1) begin: g3
    assign hit_l3[i] = hit_l2[2*i+1] | hit_l2[2*i];
    assign idx_l3[i] = hit_l2[2*i+1] ? {1'b1, idx_l2[2*i+1]} : {1'b0, idx_l2[2*i]};
  end
  for (i = 0; i < 2; i = i + 1) begin: g4
    assign hit_l4[i] = hit_l3[2*i+1] | hit_l3[2*i];
    assign idx_l4[i] = hit_l3[2*i+1] ? {1'b1, idx_l3[2*i+1]} : {1'b0, idx_l3[2*i]};
  end
  assign hit_l5 = hit_l4[1] | hit_l4[0];
  assign idx_l5 = hit_l4[1] ? {1'b1, idx_l4[1]} : {1'b0, idx_l4[0]};
endgenerate

wire [5:0] chosen_0 = hit_l5 ? {1'b1, idx_l5} : 6'd0;

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

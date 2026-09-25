module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire [15:0] v1;
wire [15:0] idx1;

wire [7:0] v2;
wire [1:0] idx2 [0:7];

wire [3:0] v3;
wire [2:0] idx3 [0:3];

wire [1:0] v4;
wire [3:0] idx4 [0:1];

wire v5;
wire [4:0] idx5;

genvar i;
generate
  for (i=0;i<16;i=i+1) begin: G1
    assign v1[i] = a_i[2*i+1] | a_i[2*i];
    assign idx1[i] = a_i[2*i+1];
  end
  for (i=0;i<8;i=i+1) begin: G2
    assign v2[i] = v1[2*i+1] | v1[2*i];
    assign idx2[i] = v1[2*i+1] ? {1'b1, idx1[2*i+1]} : {1'b0, idx1[2*i]};
  end
  for (i=0;i<4;i=i+1) begin: G3
    assign v3[i] = v2[2*i+1] | v2[2*i];
    assign idx3[i] = v2[2*i+1] ? {1'b1, idx2[2*i+1]} : {1'b0, idx2[2*i]};
  end
  for (i=0;i<2;i=i+1) begin: G4
    assign v4[i] = v3[2*i+1] | v3[2*i];
    assign idx4[i] = v3[2*i+1] ? {1'b1, idx3[2*i+1]} : {1'b0, idx3[2*i]};
  end
endgenerate

assign v5 = v4[1] | v4[0];
assign idx5 = v4[1] ? {1'b1, idx4[1]} : {1'b0, idx4[0]};

wire [5:0] chosen_0 = v5 ? {1'b1, idx5} : 6'd0;

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

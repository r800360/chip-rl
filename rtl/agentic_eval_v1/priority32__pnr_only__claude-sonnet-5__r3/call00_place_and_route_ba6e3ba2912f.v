module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire [15:0] hit1;
wire [15:0] idx1;

genvar gi;
generate
  for (gi = 0; gi < 16; gi = gi + 1) begin : L1
    assign hit1[gi] = a_i[2*gi+1] | a_i[2*gi];
    assign idx1[gi] = a_i[2*gi+1];
  end
endgenerate

wire [7:0] hit2;
wire [15:0] idx2;
generate
  for (gi = 0; gi < 8; gi = gi + 1) begin : L2
    assign hit2[gi] = hit1[2*gi+1] | hit1[2*gi];
    assign idx2[2*gi+1 -: 2] = hit1[2*gi+1] ? {1'b1, idx1[2*gi+1]} : {1'b0, idx1[2*gi]};
  end
endgenerate

wire [3:0] hit3;
wire [11:0] idx3;
generate
  for (gi = 0; gi < 4; gi = gi + 1) begin : L3
    assign hit3[gi] = hit2[2*gi+1] | hit2[2*gi];
    assign idx3[3*gi+2 -: 3] = hit2[2*gi+1] ? {1'b1, idx2[4*gi+3 -: 2]} : {1'b0, idx2[4*gi+1 -: 2]};
  end
endgenerate

wire [1:0] hit4;
wire [7:0] idx4;
generate
  for (gi = 0; gi < 2; gi = gi + 1) begin : L4
    assign hit4[gi] = hit3[2*gi+1] | hit3[2*gi];
    assign idx4[4*gi+3 -: 4] = hit3[2*gi+1] ? {1'b1, idx3[6*gi+5 -: 3]} : {1'b0, idx3[6*gi+2 -: 3]};
  end
endgenerate

wire hit5;
wire [4:0] idx5;
assign hit5 = hit4[1] | hit4[0];
assign idx5 = hit4[1] ? {1'b1, idx4[7:4]} : {1'b0, idx4[3:0]};

wire [5:0] chosen_0 = hit5 ? {1'b1, idx5} : 6'd0;

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

module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire [1:0] s1 [0:15];
wire [2:0] s2 [0:7];
wire [3:0] s3 [0:3];
wire [4:0] s4 [0:1];
wire [5:0] s5;

genvar i;
generate
  for (i = 0; i < 16; i = i + 1) begin : g1
    assign s1[i] = a_i[2*i] + a_i[2*i+1];
  end
  for (i = 0; i < 8; i = i + 1) begin : g2
    assign s2[i] = s1[2*i] + s1[2*i+1];
  end
  for (i = 0; i < 4; i = i + 1) begin : g3
    assign s3[i] = s2[2*i] + s2[2*i+1];
  end
  for (i = 0; i < 2; i = i + 1) begin : g4
    assign s4[i] = s3[2*i] + s3[2*i+1];
  end
endgenerate
assign s5 = s4[0] + s4[1];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= s5;
    end
end
endmodule
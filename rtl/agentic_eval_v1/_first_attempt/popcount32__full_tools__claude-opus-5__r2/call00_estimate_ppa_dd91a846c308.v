module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [1:0] l2 [0:15];
wire [2:0] l4 [0:7];
wire [3:0] l8 [0:3];
wire [4:0] l16 [0:1];
wire [5:0] tot;
genvar i;
generate
  for (i=0;i<16;i=i+1) begin : g2
    assign l2[i] = a_i[2*i] + a_i[2*i+1];
  end
  for (i=0;i<8;i=i+1) begin : g4
    assign l4[i] = l2[2*i] + l2[2*i+1];
  end
  for (i=0;i<4;i=i+1) begin : g8
    assign l8[i] = l4[2*i] + l4[2*i+1];
  end
  for (i=0;i<2;i=i+1) begin : g16
    assign l16[i] = l8[2*i] + l8[2*i+1];
  end
endgenerate
assign tot = l16[0] + l16[1];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= tot;
    end
end
endmodule
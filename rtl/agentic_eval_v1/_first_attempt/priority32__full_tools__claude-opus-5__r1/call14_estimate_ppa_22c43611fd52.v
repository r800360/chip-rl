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
wire [7:0]  v2;
wire [3:0]  v3;
wire [1:0]  v4;
wire [7:0]  d2a;
wire [11:0] d3a;
wire [7:0]  d4a;
genvar i;
generate
for (i = 0; i < 16; i = i + 1) begin : g1
  assign v1[i] = a_i[2*i+1] | a_i[2*i];
end
for (i = 0; i < 8; i = i + 1) begin : g2
  assign v2[i] = v1[2*i+1] | v1[2*i];
  assign d2a[2*i+1] = v1[2*i+1];
  assign d2a[2*i+0] = v1[2*i+1] ? a_i[4*i+3] : a_i[4*i+1];
end
for (i = 0; i < 4; i = i + 1) begin : g3
  assign v3[i] = v2[2*i+1] | v2[2*i];
  assign d3a[3*i+2] = v2[2*i+1];
  assign d3a[3*i+1] = v2[2*i+1] ? d2a[(2*i+1)*2+1] : d2a[(2*i)*2+1];
  assign d3a[3*i+0] = v2[2*i+1] ? d2a[(2*i+1)*2+0] : d2a[(2*i)*2+0];
end
for (i = 0; i < 2; i = i + 1) begin : g4
  assign v4[i] = v3[2*i+1] | v3[2*i];
  assign d4a[4*i+3] = v3[2*i+1];
  assign d4a[4*i+2] = v3[2*i+1] ? d3a[(2*i+1)*3+2] : d3a[(2*i)*3+2];
  assign d4a[4*i+1] = v3[2*i+1] ? d3a[(2*i+1)*3+1] : d3a[(2*i)*3+1];
  assign d4a[4*i+0] = v3[2*i+1] ? d3a[(2*i+1)*3+0] : d3a[(2*i)*3+0];
end
endgenerate
wire hit = v4[1] | v4[0];
wire [5:0] chosen_0 = {hit, v4[1],
                       v4[1] ? d4a[7] : d4a[3],
                       v4[1] ? d4a[6] : d4a[2],
                       v4[1] ? d4a[5] : d4a[1],
                       v4[1] ? d4a[4] : d4a[0]};
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

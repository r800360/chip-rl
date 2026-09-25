module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

genvar i;

wire [15:0] h1;
wire [0:0] idx1 [0:15];
generate
  for (i=0;i<16;i=i+1) begin: L1
    assign h1[i] = a_i[2*i+1] | a_i[2*i];
    assign idx1[i][0] = a_i[2*i+1];
  end
endgenerate

wire [7:0] h2;
wire [1:0] idx2 [0:7];
generate
  for (i=0;i<8;i=i+1) begin: L2
    assign h2[i] = h1[2*i+1] | h1[2*i];
    assign idx2[i] = {h1[2*i+1], h1[2*i+1] ? idx1[2*i+1][0] : idx1[2*i][0]};
  end
endgenerate

wire [3:0] h3;
wire [2:0] idx3 [0:3];
generate
  for (i=0;i<4;i=i+1) begin: L3
    assign h3[i] = h2[2*i+1] | h2[2*i];
    assign idx3[i] = {h2[2*i+1], h2[2*i+1] ? idx2[2*i+1] : idx2[2*i]};
  end
endgenerate

wire [1:0] h4;
wire [3:0] idx4 [0:1];
generate
  for (i=0;i<2;i=i+1) begin: L4
    assign h4[i] = h3[2*i+1] | h3[2*i];
    assign idx4[i] = {h3[2*i+1], h3[2*i+1] ? idx3[2*i+1] : idx3[2*i]};
  end
endgenerate

wire hit_0 = h4[1] | h4[0];
wire [4:0] idx_0 = {h4[1], h4[1] ? idx4[1] : idx4[0]};

wire [5:0] chosen_0 = {hit_0, idx_0};

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

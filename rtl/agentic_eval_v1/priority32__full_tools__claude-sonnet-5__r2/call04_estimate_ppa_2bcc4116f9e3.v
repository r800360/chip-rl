module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Tree-based leading-one detector (balanced, log-depth)
wire        v1  [0:15];
wire        v2  [0:7];
wire        v3  [0:3];
wire        v4  [0:1];
wire        v5;

wire [0:0] s1  [0:15]; // index bit chosen at 2-group (1 bit)
wire [1:0] s2  [0:7];
wire [2:0] s3  [0:3];
wire [3:0] s4  [0:1];
wire [4:0] s5;

genvar i;
generate
  for (i = 0; i < 16; i = i + 1) begin : g1
    assign v1[i]   = a_i[2*i+1] | a_i[2*i];
    assign s1[i]   = a_i[2*i+1] ? 1'b1 : 1'b0;
  end
  for (i = 0; i < 8; i = i + 1) begin : g2
    assign v2[i] = v1[2*i+1] | v1[2*i];
    assign s2[i] = v1[2*i+1] ? {1'b1, s1[2*i+1]} : {1'b0, s1[2*i]};
  end
  for (i = 0; i < 4; i = i + 1) begin : g3
    assign v3[i] = v2[2*i+1] | v2[2*i];
    assign s3[i] = v2[2*i+1] ? {1'b1, s2[2*i+1]} : {1'b0, s2[2*i]};
  end
  for (i = 0; i < 2; i = i + 1) begin : g4
    assign v4[i] = v3[2*i+1] | v3[2*i];
    assign s4[i] = v3[2*i+1] ? {1'b1, s3[2*i+1]} : {1'b0, s3[2*i]};
  end
endgenerate

assign v5 = v4[1] | v4[0];
assign s5 = v4[1] ? {1'b1, s4[1]} : {1'b0, s4[0]};

wire [5:0] chosen_0 = {v5, s5};

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

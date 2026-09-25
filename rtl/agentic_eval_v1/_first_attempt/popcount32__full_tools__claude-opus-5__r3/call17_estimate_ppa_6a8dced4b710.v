module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
genvar i;
wire [10:0] sw, cw;
generate for (i=0;i<10;i=i+1) begin : gfa
  assign sw[i] = a_i[3*i] ^ a_i[3*i+1] ^ a_i[3*i+2];
  assign cw[i] = (a_i[3*i] & a_i[3*i+1]) | (a_i[3*i] & a_i[3*i+2]) | (a_i[3*i+1] & a_i[3*i+2]);
end endgenerate
assign sw[10] = a_i[30] ^ a_i[31];
assign cw[10] = a_i[30] & a_i[31];

wire [3:0] A = {3'b0,sw[0]}+{3'b0,sw[1]}+{3'b0,sw[2]}+{3'b0,sw[3]}+{3'b0,sw[4]}+{3'b0,sw[5]}
              +{3'b0,sw[6]}+{3'b0,sw[7]}+{3'b0,sw[8]}+{3'b0,sw[9]}+{3'b0,sw[10]};
wire [3:0] B = {3'b0,cw[0]}+{3'b0,cw[1]}+{3'b0,cw[2]}+{3'b0,cw[3]}+{3'b0,cw[4]}+{3'b0,cw[5]}
              +{3'b0,cw[6]}+{3'b0,cw[7]}+{3'b0,cw[8]}+{3'b0,cw[9]}+{3'b0,cw[10]};
wire [5:0] tot = {2'b0,A} + {1'b0,B,1'b0};

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
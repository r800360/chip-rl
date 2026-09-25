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
wire [2:0] g [0:7];
generate for (i=0;i<8;i=i+1) begin : gg
  assign g[i] = {2'b0,a_i[4*i]} + {2'b0,a_i[4*i+1]} + {2'b0,a_i[4*i+2]} + {2'b0,a_i[4*i+3]};
end endgenerate
wire [3:0] t0 = g[0] + g[1];
wire [3:0] t1 = g[2] + g[3];
wire [3:0] t2 = g[4] + g[5];
wire [3:0] t3 = g[6] + g[7];
wire [4:0] u0 = t0 + t1;
wire [4:0] u1 = t2 + t3;
wire [5:0] tot = u0 + u1;

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
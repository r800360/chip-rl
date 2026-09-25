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
// level1: 10 full adders
wire [9:0] s1, c1;
generate for (i=0;i<10;i=i+1) begin : gfa
  assign s1[i] = a_i[3*i] ^ a_i[3*i+1] ^ a_i[3*i+2];
  assign c1[i] = (a_i[3*i] & a_i[3*i+1]) | (a_i[3*i] & a_i[3*i+2]) | (a_i[3*i+1] & a_i[3*i+2]);
end endgenerate
// weight1 pool: s1[9:0], a30, a31  (12 bits) -> 4 FAs
wire [11:0] w1 = {a_i[31], a_i[30], s1};
wire [3:0] s2, c2;
generate for (i=0;i<4;i=i+1) begin : gfa2
  assign s2[i] = w1[3*i] ^ w1[3*i+1] ^ w1[3*i+2];
  assign c2[i] = (w1[3*i] & w1[3*i+1]) | (w1[3*i] & w1[3*i+2]) | (w1[3*i+1] & w1[3*i+2]);
end endgenerate
// weight1 remaining: s2[3:0] -> popcount of 4 bits
wire [2:0] q1 = {2'b0,s2[0]} + {2'b0,s2[1]} + {2'b0,s2[2]} + {2'b0,s2[3]};
// weight2 pool: c1[9:0], c2[3:0] = 14 bits -> count
wire [13:0] w2 = {c2, c1};
wire [2:0] e0 = {2'b0,w2[0]}+{2'b0,w2[1]}+{2'b0,w2[2]}+{2'b0,w2[3]};
wire [2:0] e1 = {2'b0,w2[4]}+{2'b0,w2[5]}+{2'b0,w2[6]}+{2'b0,w2[7]};
wire [2:0] e2 = {2'b0,w2[8]}+{2'b0,w2[9]}+{2'b0,w2[10]}+{2'b0,w2[11]};
wire [1:0] e3 = {1'b0,w2[12]}+{1'b0,w2[13]};
wire [3:0] f0 = e0 + e1;
wire [3:0] f1 = e2 + {1'b0,e3};
wire [4:0] g0 = f0 + f1;
wire [5:0] tot = {g0,1'b0} + {3'b0,q1};

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
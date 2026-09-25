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
// level1: 10 full adders on a_i[29:0]
wire [9:0] s1, c1;
generate for (i=0;i<10;i=i+1) begin : gfa
  assign s1[i] = a_i[3*i] ^ a_i[3*i+1] ^ a_i[3*i+2];
  assign c1[i] = (a_i[3*i] & a_i[3*i+1]) | (a_i[3*i] & a_i[3*i+2]) | (a_i[3*i+1] & a_i[3*i+2]);
end endgenerate

// X = popcount of 12 weight-1 bits
wire [11:0] w1 = {a_i[31], a_i[30], s1};
wire [3:0] s2, c2;
generate for (i=0;i<4;i=i+1) begin : gfa2
  assign s2[i] = w1[3*i] ^ w1[3*i+1] ^ w1[3*i+2];
  assign c2[i] = (w1[3*i] & w1[3*i+1]) | (w1[3*i] & w1[3*i+2]) | (w1[3*i+1] & w1[3*i+2]);
end endgenerate
wire [2:0] ps2 = {2'b0,s2[0]} + {2'b0,s2[1]} + {2'b0,s2[2]} + {2'b0,s2[3]};
wire [2:0] pc2 = {2'b0,c2[0]} + {2'b0,c2[1]} + {2'b0,c2[2]} + {2'b0,c2[3]};
wire [3:0] X = ps2 + {pc2[2:0],1'b0};

// Y = popcount of 10 weight-2 bits
wire [2:0] s3, c3;
generate for (i=0;i<3;i=i+1) begin : gfa3
  assign s3[i] = c1[3*i] ^ c1[3*i+1] ^ c1[3*i+2];
  assign c3[i] = (c1[3*i] & c1[3*i+1]) | (c1[3*i] & c1[3*i+2]) | (c1[3*i+1] & c1[3*i+2]);
end endgenerate
wire [2:0] ps3 = {2'b0,s3[0]} + {2'b0,s3[1]} + {2'b0,s3[2]} + {2'b0,c1[9]};
wire [1:0] pc3 = {1'b0,c3[0]} + {1'b0,c3[1]} + {1'b0,c3[2]};
wire [3:0] Y = ps3 + {pc3,1'b0};

wire [5:0] tot = {1'b0,X} + {Y,1'b0};

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
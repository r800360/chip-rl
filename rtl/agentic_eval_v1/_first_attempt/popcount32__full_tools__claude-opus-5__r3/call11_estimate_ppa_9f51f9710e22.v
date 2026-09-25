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
wire [1:0] n [0:10];
generate for (i=0;i<10;i=i+1) begin : gfa
  assign n[i][0] = a_i[3*i] ^ a_i[3*i+1] ^ a_i[3*i+2];
  assign n[i][1] = (a_i[3*i] & a_i[3*i+1]) | (a_i[3*i] & a_i[3*i+2]) | (a_i[3*i+1] & a_i[3*i+2]);
end endgenerate
assign n[10][0] = a_i[30] ^ a_i[31];
assign n[10][1] = a_i[30] & a_i[31];

wire [2:0] m0 = n[0] + n[1];
wire [2:0] m1 = n[2] + n[3];
wire [2:0] m2 = n[4] + n[5];
wire [2:0] m3 = n[6] + n[7];
wire [2:0] m4 = n[8] + n[9];
wire [5:0] tot = {3'b0,m0} + {3'b0,m1} + {3'b0,m2} + {3'b0,m3} + {3'b0,m4} + {4'b0,n[10]};

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
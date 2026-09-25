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

wire [2:0] m [0:5];
generate for (i=0;i<5;i=i+1) begin : gm
  wire s0 = n[2*i][0] ^ n[2*i+1][0];
  wire g0 = n[2*i][0] & n[2*i+1][0];
  wire x1 = n[2*i][1] ^ n[2*i+1][1];
  wire p1 = n[2*i][1] & n[2*i+1][1];
  assign m[i][0] = s0;
  assign m[i][1] = x1 ^ g0;
  assign m[i][2] = p1 | (g0 & x1);
end endgenerate
assign m[5] = {1'b0, n[10]};

// explicit 3-bit adders -> 4-bit
wire [3:0] k [0:2];
generate for (i=0;i<3;i=i+1) begin : gk
  wire [2:0] A = m[2*i];
  wire [2:0] B = m[2*i+1];
  wire p0 = A[0] ^ B[0];
  wire c0 = A[0] & B[0];
  wire p1 = A[1] ^ B[1];
  wire q1 = A[1] & B[1];
  wire p2 = A[2] ^ B[2];
  wire q2 = A[2] & B[2];
  wire c1 = q1 | (p1 & c0);
  wire c2 = q2 | (p2 & c1);
  assign k[i][0] = p0;
  assign k[i][1] = p1 ^ c0;
  assign k[i][2] = p2 ^ c1;
  assign k[i][3] = c2;
end endgenerate

wire [4:0] j0 = k[0] + k[1];
wire [5:0] tot = j0 + k[2];

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
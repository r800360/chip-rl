module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [1:0] g0 = a_i[0]+a_i[1]+a_i[2];
wire [1:0] g1 = a_i[3]+a_i[4]+a_i[5];
wire [1:0] g2 = a_i[6]+a_i[7]+a_i[8];
wire [1:0] g3 = a_i[9]+a_i[10]+a_i[11];
wire [1:0] g4 = a_i[12]+a_i[13]+a_i[14];
wire [1:0] g5 = a_i[15]+a_i[16]+a_i[17];
wire [1:0] g6 = a_i[18]+a_i[19]+a_i[20];
wire [1:0] g7 = a_i[21]+a_i[22]+a_i[23];
wire [1:0] g8 = a_i[24]+a_i[25]+a_i[26];
wire [1:0] g9 = a_i[27]+a_i[28]+a_i[29];

wire [3:0] h0 = g0+g1+g2;
wire [3:0] h1 = g3+g4+g5;
wire [3:0] h2 = g6+g7+g8;
wire [1:0] h3 = a_i[30]+a_i[31];

wire [4:0] k0 = h0+h1;
wire [4:0] k1 = h2+g9+h3;

wire [5:0] total_0 = k0+k1;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= total_0;
    end
end
endmodule
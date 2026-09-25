module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [1:0] c0 = {1'b0,a_i[0]}+{1'b0,a_i[1]};
wire [1:0] c1 = {1'b0,a_i[2]}+{1'b0,a_i[3]};
wire [1:0] c2 = {1'b0,a_i[4]}+{1'b0,a_i[5]};
wire [1:0] c3 = {1'b0,a_i[6]}+{1'b0,a_i[7]};
wire [1:0] c4 = {1'b0,a_i[8]}+{1'b0,a_i[9]};
wire [1:0] c5 = {1'b0,a_i[10]}+{1'b0,a_i[11]};
wire [1:0] c6 = {1'b0,a_i[12]}+{1'b0,a_i[13]};
wire [1:0] c7 = {1'b0,a_i[14]}+{1'b0,a_i[15]};
wire [1:0] c8 = {1'b0,a_i[16]}+{1'b0,a_i[17]};
wire [1:0] c9 = {1'b0,a_i[18]}+{1'b0,a_i[19]};
wire [1:0] c10 = {1'b0,a_i[20]}+{1'b0,a_i[21]};
wire [1:0] c11 = {1'b0,a_i[22]}+{1'b0,a_i[23]};
wire [1:0] c12 = {1'b0,a_i[24]}+{1'b0,a_i[25]};
wire [1:0] c13 = {1'b0,a_i[26]}+{1'b0,a_i[27]};
wire [1:0] c14 = {1'b0,a_i[28]}+{1'b0,a_i[29]};
wire [1:0] c15 = {1'b0,a_i[30]}+{1'b0,a_i[31]};
wire [2:0] d0 = {1'b0,c0}+{1'b0,c1};
wire [2:0] d1 = {1'b0,c2}+{1'b0,c3};
wire [2:0] d2 = {1'b0,c4}+{1'b0,c5};
wire [2:0] d3 = {1'b0,c6}+{1'b0,c7};
wire [2:0] d4 = {1'b0,c8}+{1'b0,c9};
wire [2:0] d5 = {1'b0,c10}+{1'b0,c11};
wire [2:0] d6 = {1'b0,c12}+{1'b0,c13};
wire [2:0] d7 = {1'b0,c14}+{1'b0,c15};
wire [3:0] e0 = {1'b0,d0}+{1'b0,d1};
wire [3:0] e1 = {1'b0,d2}+{1'b0,d3};
wire [3:0] e2 = {1'b0,d4}+{1'b0,d5};
wire [3:0] e3 = {1'b0,d6}+{1'b0,d7};
wire [4:0] f0 = {1'b0,e0}+{1'b0,e1};
wire [4:0] f1 = {1'b0,e2}+{1'b0,e3};
wire [5:0] total_0 = {1'b0,f0}+{1'b0,f1};
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
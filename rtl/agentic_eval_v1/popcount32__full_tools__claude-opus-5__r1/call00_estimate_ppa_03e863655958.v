module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);
wire [1:0] l0_0 = a_i[0]+a_i[1];
wire [1:0] l0_1 = a_i[2]+a_i[3];
wire [1:0] l0_2 = a_i[4]+a_i[5];
wire [1:0] l0_3 = a_i[6]+a_i[7];
wire [1:0] l0_4 = a_i[8]+a_i[9];
wire [1:0] l0_5 = a_i[10]+a_i[11];
wire [1:0] l0_6 = a_i[12]+a_i[13];
wire [1:0] l0_7 = a_i[14]+a_i[15];
wire [1:0] l0_8 = a_i[16]+a_i[17];
wire [1:0] l0_9 = a_i[18]+a_i[19];
wire [1:0] l0_10 = a_i[20]+a_i[21];
wire [1:0] l0_11 = a_i[22]+a_i[23];
wire [1:0] l0_12 = a_i[24]+a_i[25];
wire [1:0] l0_13 = a_i[26]+a_i[27];
wire [1:0] l0_14 = a_i[28]+a_i[29];
wire [1:0] l0_15 = a_i[30]+a_i[31];

wire [2:0] l1_0 = l0_0+l0_1;
wire [2:0] l1_1 = l0_2+l0_3;
wire [2:0] l1_2 = l0_4+l0_5;
wire [2:0] l1_3 = l0_6+l0_7;
wire [2:0] l1_4 = l0_8+l0_9;
wire [2:0] l1_5 = l0_10+l0_11;
wire [2:0] l1_6 = l0_12+l0_13;
wire [2:0] l1_7 = l0_14+l0_15;

wire [3:0] l2_0 = l1_0+l1_1;
wire [3:0] l2_1 = l1_2+l1_3;
wire [3:0] l2_2 = l1_4+l1_5;
wire [3:0] l2_3 = l1_6+l1_7;

wire [4:0] l3_0 = l2_0+l2_1;
wire [4:0] l3_1 = l2_2+l2_3;

wire [5:0] total_0 = l3_0+l3_1;

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
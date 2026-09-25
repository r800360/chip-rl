module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Balanced tree - middle ground between original and #2
wire [4:0] s0 = a_i[0] + a_i[1] + a_i[2] + a_i[3] + a_i[4];
wire [4:0] s1 = a_i[5] + a_i[6] + a_i[7] + a_i[8] + a_i[9];
wire [4:0] s2 = a_i[10] + a_i[11] + a_i[12] + a_i[13] + a_i[14];
wire [4:0] s3 = a_i[15] + a_i[16] + a_i[17] + a_i[18] + a_i[19];
wire [4:0] s4 = a_i[20] + a_i[21] + a_i[22] + a_i[23] + a_i[24];
wire [4:0] s5 = a_i[25] + a_i[26] + a_i[27] + a_i[28] + a_i[29];
wire [1:0] s6 = a_i[30] + a_i[31];

wire [5:0] sum0 = {s0[4], s0} + {s1[4], s1};
wire [5:0] sum1 = {s2[4], s2} + {s3[4], s3};
wire [5:0] sum2 = {s4[4], s4} + {s5[4], s5};
wire [5:0] sum3 = {4'd0, s6};

wire [6:0] sum01 = {sum0[5], sum0} + {sum1[5], sum1};
wire [6:0] sum23 = {sum2[5], sum2} + {sum3[5], sum3};

wire [6:0] pc_0_full = sum01 + sum23;
wire [5:0] pc_0 = pc_0_full[5:0];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= pc_0;
    end
end
endmodule

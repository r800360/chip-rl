module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// 5-stage tree for better balance and pipelining friendly

// Stage 1: Count bits in groups of 2
wire [1:0] s1_0  = {a_i[1], a_i[0]};
wire [1:0] s1_1  = {a_i[3], a_i[2]};
wire [1:0] s1_2  = {a_i[5], a_i[4]};
wire [1:0] s1_3  = {a_i[7], a_i[6]};
wire [1:0] s1_4  = {a_i[9], a_i[8]};
wire [1:0] s1_5  = {a_i[11], a_i[10]};
wire [1:0] s1_6  = {a_i[13], a_i[12]};
wire [1:0] s1_7  = {a_i[15], a_i[14]};
wire [1:0] s1_8  = {a_i[17], a_i[16]};
wire [1:0] s1_9  = {a_i[19], a_i[18]};
wire [1:0] s1_10 = {a_i[21], a_i[20]};
wire [1:0] s1_11 = {a_i[23], a_i[22]};
wire [1:0] s1_12 = {a_i[25], a_i[24]};
wire [1:0] s1_13 = {a_i[27], a_i[26]};
wire [1:0] s1_14 = {a_i[29], a_i[28]};
wire [1:0] s1_15 = {a_i[31], a_i[30]};

wire [4:0] cnt1_0 = s1_0[0] + s1_0[1] + s1_1[0] + s1_1[1];
wire [4:0] cnt1_1 = s1_2[0] + s1_2[1] + s1_3[0] + s1_3[1];
wire [4:0] cnt1_2 = s1_4[0] + s1_4[1] + s1_5[0] + s1_5[1];
wire [4:0] cnt1_3 = s1_6[0] + s1_6[1] + s1_7[0] + s1_7[1];
wire [4:0] cnt1_4 = s1_8[0] + s1_8[1] + s1_9[0] + s1_9[1];
wire [4:0] cnt1_5 = s1_10[0] + s1_10[1] + s1_11[0] + s1_11[1];
wire [4:0] cnt1_6 = s1_12[0] + s1_12[1] + s1_13[0] + s1_13[1];
wire [4:0] cnt1_7 = s1_14[0] + s1_14[1] + s1_15[0] + s1_15[1];

// Stage 2: Sum pairs of stage 1 results
wire [5:0] cnt2_0 = {1'b0, cnt1_0} + {1'b0, cnt1_1};
wire [5:0] cnt2_1 = {1'b0, cnt1_2} + {1'b0, cnt1_3};
wire [5:0] cnt2_2 = {1'b0, cnt1_4} + {1'b0, cnt1_5};
wire [5:0] cnt2_3 = {1'b0, cnt1_6} + {1'b0, cnt1_7};

// Stage 3: Sum pairs of stage 2 results
wire [6:0] cnt3_0 = {1'b0, cnt2_0} + {1'b0, cnt2_1};
wire [6:0] cnt3_1 = {1'b0, cnt2_2} + {1'b0, cnt2_3};

// Stage 4: Final sum
wire [6:0] total_0 = cnt3_0 + cnt3_1;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= total_0[5:0];
    end
end
endmodule

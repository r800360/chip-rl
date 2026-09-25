module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Stage 1: Sum groups of 4 bits (creates 8 3-bit intermediate results)
wire [2:0] stage1_0 = {2'd0, a_i[0]} + {2'd0, a_i[1]} + {2'd0, a_i[2]} + {2'd0, a_i[3]};
wire [2:0] stage1_1 = {2'd0, a_i[4]} + {2'd0, a_i[5]} + {2'd0, a_i[6]} + {2'd0, a_i[7]};
wire [2:0] stage1_2 = {2'd0, a_i[8]} + {2'd0, a_i[9]} + {2'd0, a_i[10]} + {2'd0, a_i[11]};
wire [2:0] stage1_3 = {2'd0, a_i[12]} + {2'd0, a_i[13]} + {2'd0, a_i[14]} + {2'd0, a_i[15]};
wire [2:0] stage1_4 = {2'd0, a_i[16]} + {2'd0, a_i[17]} + {2'd0, a_i[18]} + {2'd0, a_i[19]};
wire [2:0] stage1_5 = {2'd0, a_i[20]} + {2'd0, a_i[21]} + {2'd0, a_i[22]} + {2'd0, a_i[23]};
wire [2:0] stage1_6 = {2'd0, a_i[24]} + {2'd0, a_i[25]} + {2'd0, a_i[26]} + {2'd0, a_i[27]};
wire [2:0] stage1_7 = {2'd0, a_i[28]} + {2'd0, a_i[29]} + {2'd0, a_i[30]} + {2'd0, a_i[31]};

// Stage 2: Sum pairs of stage1 results (creates 4 4-bit results)
wire [3:0] stage2_0 = {1'd0, stage1_0} + {1'd0, stage1_1};
wire [3:0] stage2_1 = {1'd0, stage1_2} + {1'd0, stage1_3};
wire [3:0] stage2_2 = {1'd0, stage1_4} + {1'd0, stage1_5};
wire [3:0] stage2_3 = {1'd0, stage1_6} + {1'd0, stage1_7};

// Stage 3: Sum pairs of stage2 results (creates 2 5-bit results)
wire [4:0] stage3_0 = {1'd0, stage2_0} + {1'd0, stage2_1};
wire [4:0] stage3_1 = {1'd0, stage2_2} + {1'd0, stage2_3};

// Stage 4: Final sum (6-bit result)
wire [5:0] pc_0 = {1'd0, stage3_0} + {1'd0, stage3_1};

wire [5:0] total_0 = pc_0;

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

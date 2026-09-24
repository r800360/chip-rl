module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire [5:0] pc_0 = 6'd0 + {5'd0, a_i[0]} + {5'd0, a_i[1]} + {5'd0, a_i[2]} + {5'd0, a_i[3]} + {5'd0, a_i[4]} + {5'd0, a_i[5]} + {5'd0, a_i[6]} + {5'd0, a_i[7]};
wire [5:0] pc_1 = 6'd0 + {5'd0, a_i[8]} + {5'd0, a_i[9]} + {5'd0, a_i[10]} + {5'd0, a_i[11]};
wire [5:0] pc_2 = 6'd0 + {5'd0, a_i[12]} + {5'd0, a_i[13]};
wire [5:0] pc_3 = 6'd0 + {5'd0, a_i[14]};
wire [5:0] pc_4 = 6'd0 + {5'd0, a_i[15]} + {5'd0, a_i[16]} + {5'd0, a_i[17]} + {5'd0, a_i[18]} + {5'd0, a_i[19]};
wire [5:0] pc_5 = 6'd0 + {5'd0, a_i[20]} + {5'd0, a_i[21]};
wire [5:0] pc_6 = 6'd0 + {5'd0, a_i[22]};
wire [5:0] pc_7 = 6'd0 + {5'd0, a_i[23]};
wire [5:0] pc_8 = 6'd0 + {5'd0, a_i[24]} + {5'd0, a_i[25]} + {5'd0, a_i[26]} + {5'd0, a_i[27]} + {5'd0, a_i[28]} + {5'd0, a_i[29]} + {5'd0, a_i[30]};
wire [5:0] pc_9 = 6'd0 + {5'd0, a_i[31]};

wire [5:0] total_0 = pc_0;
wire [5:0] total_1 = total_0 + pc_1;
wire [5:0] total_2 = total_1 + pc_2;
wire [5:0] total_3 = total_2 + pc_3;
wire [5:0] total_4 = total_3 + pc_4;
wire [5:0] total_5 = total_4 + pc_5;
wire [5:0] total_6 = total_5 + pc_6;
wire [5:0] total_7 = total_6 + pc_7;
wire [5:0] total_8 = total_7 + pc_8;
wire [5:0] total_9 = total_8 + pc_9;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= total_9;
    end
end
endmodule

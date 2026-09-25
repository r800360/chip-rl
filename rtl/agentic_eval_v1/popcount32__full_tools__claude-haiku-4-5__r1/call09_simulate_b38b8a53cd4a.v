module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire [7:0] pc_0 = {7'd0, a_i[0]} + {7'd0, a_i[1]} + {7'd0, a_i[2]} + {7'd0, a_i[3]} +
                   {7'd0, a_i[4]} + {7'd0, a_i[5]} + {7'd0, a_i[6]} + {7'd0, a_i[7]} +
                   {7'd0, a_i[8]} + {7'd0, a_i[9]} + {7'd0, a_i[10]} + {7'd0, a_i[11]} +
                   {7'd0, a_i[12]} + {7'd0, a_i[13]} + {7'd0, a_i[14]} + {7'd0, a_i[15]} +
                   {7'd0, a_i[16]} + {7'd0, a_i[17]} + {7'd0, a_i[18]} + {7'd0, a_i[19]} +
                   {7'd0, a_i[20]} + {7'd0, a_i[21]} + {7'd0, a_i[22]} + {7'd0, a_i[23]} +
                   {7'd0, a_i[24]} + {7'd0, a_i[25]} + {7'd0, a_i[26]} + {7'd0, a_i[27]} +
                   {7'd0, a_i[28]} + {7'd0, a_i[29]} + {7'd0, a_i[30]} + {7'd0, a_i[31]};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= pc_0[5:0];
    end
end
endmodule
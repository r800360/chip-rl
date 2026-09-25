module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire [8:0] pc_0 = {8'd0, a_i[0]} + {8'd0, a_i[1]} + {8'd0, a_i[2]} + {8'd0, a_i[3]} +
                   {8'd0, a_i[4]} + {8'd0, a_i[5]} + {8'd0, a_i[6]} + {8'd0, a_i[7]} +
                   {8'd0, a_i[8]} + {8'd0, a_i[9]} + {8'd0, a_i[10]} + {8'd0, a_i[11]} +
                   {8'd0, a_i[12]} + {8'd0, a_i[13]} + {8'd0, a_i[14]} + {8'd0, a_i[15]} +
                   {8'd0, a_i[16]} + {8'd0, a_i[17]} + {8'd0, a_i[18]} + {8'd0, a_i[19]} +
                   {8'd0, a_i[20]} + {8'd0, a_i[21]} + {8'd0, a_i[22]} + {8'd0, a_i[23]} +
                   {8'd0, a_i[24]} + {8'd0, a_i[25]} + {8'd0, a_i[26]} + {8'd0, a_i[27]} +
                   {8'd0, a_i[28]} + {8'd0, a_i[29]} + {8'd0, a_i[30]} + {8'd0, a_i[31]};

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
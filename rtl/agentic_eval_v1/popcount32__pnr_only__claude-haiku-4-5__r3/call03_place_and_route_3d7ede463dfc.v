module popcount32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire [5:0] pc_0;
wire [4:0] sum_low = {4'd0, a_i[0]} + {4'd0, a_i[1]} + {4'd0, a_i[2]} + {4'd0, a_i[3]} + 
                     {4'd0, a_i[4]} + {4'd0, a_i[5]} + {4'd0, a_i[6]} + {4'd0, a_i[7]} +
                     {4'd0, a_i[8]} + {4'd0, a_i[9]} + {4'd0, a_i[10]} + {4'd0, a_i[11]} +
                     {4'd0, a_i[12]} + {4'd0, a_i[13]} + {4'd0, a_i[14]} + {4'd0, a_i[15]};

wire [4:0] sum_high = {4'd0, a_i[16]} + {4'd0, a_i[17]} + {4'd0, a_i[18]} + {4'd0, a_i[19]} +
                      {4'd0, a_i[20]} + {4'd0, a_i[21]} + {4'd0, a_i[22]} + {4'd0, a_i[23]} +
                      {4'd0, a_i[24]} + {4'd0, a_i[25]} + {4'd0, a_i[26]} + {4'd0, a_i[27]} +
                      {4'd0, a_i[28]} + {4'd0, a_i[29]} + {4'd0, a_i[30]} + {4'd0, a_i[31]};

assign pc_0 = {1'd0, sum_low} + {1'd0, sum_high};

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

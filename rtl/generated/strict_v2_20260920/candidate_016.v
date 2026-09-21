module addpipe (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid_i,
    input  wire [7:0] a_i,
    input  wire [7:0] b_i,
    output reg        valid_o,
    output reg  [7:0] y_o
);

wire [7:0] sum;

wire [1:0] part_0;
assign part_0 = {1'b0, a_i[0:0]} + {1'b0, b_i[0:0]} + 1'b0;
assign sum[0:0] = part_0[0:0];

wire [1:0] part_1;
assign part_1 = {1'b0, a_i[1:1]} + {1'b0, b_i[1:1]} + part_0[1];
assign sum[1:1] = part_1[0:0];

wire [1:0] part_2;
assign part_2 = {1'b0, a_i[2:2]} + {1'b0, b_i[2:2]} + part_1[1];
assign sum[2:2] = part_2[0:0];

wire [1:0] part_3;
assign part_3 = {1'b0, a_i[3:3]} + {1'b0, b_i[3:3]} + part_2[1];
assign sum[3:3] = part_3[0:0];

wire [1:0] part_4;
assign part_4 = {1'b0, a_i[4:4]} + {1'b0, b_i[4:4]} + part_3[1];
assign sum[4:4] = part_4[0:0];

wire [1:0] part_5;
assign part_5 = {1'b0, a_i[5:5]} + {1'b0, b_i[5:5]} + part_4[1];
assign sum[5:5] = part_5[0:0];

wire [1:0] part_6;
assign part_6 = {1'b0, a_i[6:6]} + {1'b0, b_i[6:6]} + part_5[1];
assign sum[6:6] = part_6[0:0];

wire [1:0] part_7;
assign part_7 = {1'b0, a_i[7:7]} + {1'b0, b_i[7:7]} + part_6[1];
assign sum[7:7] = part_7[0:0];

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 8'd0;
    end else begin

        valid_o <= valid_i;
        case (valid_i)
            1'b1:    y_o <= sum;
            default: y_o <= y_o;
        endcase

    end
end

endmodule

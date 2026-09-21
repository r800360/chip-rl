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

wire [2:0] part_0;
assign part_0 = {1'b0, a_i[1:0]} + {1'b0, b_i[1:0]} + 1'b0;
assign sum[1:0] = part_0[1:0];

wire [2:0] part_1;
assign part_1 = {1'b0, a_i[3:2]} + {1'b0, b_i[3:2]} + part_0[2];
assign sum[3:2] = part_1[1:0];

wire [2:0] part_2;
assign part_2 = {1'b0, a_i[5:4]} + {1'b0, b_i[5:4]} + part_1[2];
assign sum[5:4] = part_2[1:0];

wire [2:0] part_3;
assign part_3 = {1'b0, a_i[7:6]} + {1'b0, b_i[7:6]} + part_2[2];
assign sum[7:6] = part_3[1:0];

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

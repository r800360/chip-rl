module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// chosen_0 directly encodes {found, idx} as a single priority-mux chain,
// avoiding a separate 32-input OR reduction for the "found" flag.
wire [5:0] chosen_0 =
    a_i[31] ? 6'd63 : a_i[30] ? 6'd62 : a_i[29] ? 6'd61 : a_i[28] ? 6'd60 :
    a_i[27] ? 6'd59 : a_i[26] ? 6'd58 : a_i[25] ? 6'd57 : a_i[24] ? 6'd56 :
    a_i[23] ? 6'd55 : a_i[22] ? 6'd54 : a_i[21] ? 6'd53 : a_i[20] ? 6'd52 :
    a_i[19] ? 6'd51 : a_i[18] ? 6'd50 : a_i[17] ? 6'd49 : a_i[16] ? 6'd48 :
    a_i[15] ? 6'd47 : a_i[14] ? 6'd46 : a_i[13] ? 6'd45 : a_i[12] ? 6'd44 :
    a_i[11] ? 6'd43 : a_i[10] ? 6'd42 : a_i[9]  ? 6'd41 : a_i[8]  ? 6'd40 :
    a_i[7]  ? 6'd39 : a_i[6]  ? 6'd38 : a_i[5]  ? 6'd37 : a_i[4]  ? 6'd36 :
    a_i[3]  ? 6'd35 : a_i[2]  ? 6'd34 : a_i[1]  ? 6'd33 : a_i[0]  ? 6'd32 :
    6'd0;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 6'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= chosen_0;
    end
end
endmodule

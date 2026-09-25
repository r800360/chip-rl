module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// balanced OR tree for hit detection (may share better with mux chain)
wire [15:0] or1;
wire [7:0]  or2;
wire [3:0]  or3;
wire [1:0]  or4;
wire        hit_0;
genvar gi;
generate
  for (gi=0; gi<16; gi=gi+1) begin: g1
    assign or1[gi] = a_i[2*gi] | a_i[2*gi+1];
  end
  for (gi=0; gi<8; gi=gi+1) begin: g2
    assign or2[gi] = or1[2*gi] | or1[2*gi+1];
  end
  for (gi=0; gi<4; gi=gi+1) begin: g3
    assign or3[gi] = or2[2*gi] | or2[2*gi+1];
  end
  for (gi=0; gi<2; gi=gi+1) begin: g4
    assign or4[gi] = or3[2*gi] | or3[2*gi+1];
  end
endgenerate
assign hit_0 = or4[0] | or4[1];

wire [4:0] idx_0 = a_i[31] ? 5'd31 : a_i[30] ? 5'd30 : a_i[29] ? 5'd29 : a_i[28] ? 5'd28 : a_i[27] ? 5'd27 : a_i[26] ? 5'd26 : a_i[25] ? 5'd25 : a_i[24] ? 5'd24 : a_i[23] ? 5'd23 : a_i[22] ? 5'd22 : a_i[21] ? 5'd21 : a_i[20] ? 5'd20 : a_i[19] ? 5'd19 : a_i[18] ? 5'd18 : a_i[17] ? 5'd17 : a_i[16] ? 5'd16 : a_i[15] ? 5'd15 : a_i[14] ? 5'd14 : a_i[13] ? 5'd13 : a_i[12] ? 5'd12 : a_i[11] ? 5'd11 : a_i[10] ? 5'd10 : a_i[9] ? 5'd9 : a_i[8] ? 5'd8 : a_i[7] ? 5'd7 : a_i[6] ? 5'd6 : a_i[5] ? 5'd5 : a_i[4] ? 5'd4 : a_i[3] ? 5'd3 : a_i[2] ? 5'd2 : a_i[1] ? 5'd1 : 5'd0;

wire [5:0] chosen_0 = {hit_0, idx_0};

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

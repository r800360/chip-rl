module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

// Balanced tree unsigned comparator: produces (gt,lt) pair per level
wire [15:0] lvl1_lt, lvl1_gt;
genvar i;
generate
    for (i=0;i<16;i=i+1) begin: g1
        wire ai0 = a_i[2*i];
        wire ai1 = a_i[2*i+1];
        wire bi0 = b_i[2*i];
        wire bi1 = b_i[2*i+1];
        wire lt0 = (ai0<bi0);
        wire gt0 = (ai0>bi0);
        wire lt1 = (ai1<bi1);
        wire gt1 = (ai1>bi1);
        assign lvl1_lt[i] = lt1 | (~gt1 & ~lt1 & lt0);
        assign lvl1_gt[i] = gt1 | (~gt1 & ~lt1 & gt0);
    end
endgenerate

wire [7:0] lvl2_lt, lvl2_gt;
generate
    for (i=0;i<8;i=i+1) begin: g2
        wire lt0 = lvl1_lt[2*i];
        wire gt0 = lvl1_gt[2*i];
        wire lt1 = lvl1_lt[2*i+1];
        wire gt1 = lvl1_gt[2*i+1];
        assign lvl2_lt[i] = lt1 | (~gt1 & ~lt1 & lt0);
        assign lvl2_gt[i] = gt1 | (~gt1 & ~lt1 & gt0);
    end
endgenerate

wire [3:0] lvl3_lt, lvl3_gt;
generate
    for (i=0;i<4;i=i+1) begin: g3
        wire lt0 = lvl2_lt[2*i];
        wire gt0 = lvl2_gt[2*i];
        wire lt1 = lvl2_lt[2*i+1];
        wire gt1 = lvl2_gt[2*i+1];
        assign lvl3_lt[i] = lt1 | (~gt1 & ~lt1 & lt0);
        assign lvl3_gt[i] = gt1 | (~gt1 & ~lt1 & gt0);
    end
endgenerate

wire [1:0] lvl4_lt, lvl4_gt;
generate
    for (i=0;i<2;i=i+1) begin: g4
        wire lt0 = lvl3_lt[2*i];
        wire gt0 = lvl3_gt[2*i];
        wire lt1 = lvl3_lt[2*i+1];
        wire gt1 = lvl3_gt[2*i+1];
        assign lvl4_lt[i] = lt1 | (~gt1 & ~lt1 & lt0);
        assign lvl4_gt[i] = gt1 | (~gt1 & ~lt1 & gt0);
    end
endgenerate

wire lt0_f = lvl4_lt[0];
wire gt0_f = lvl4_gt[0];
wire lt1_f = lvl4_lt[1];
wire gt1_f = lvl4_gt[1];
wire cmp_0 = lt1_f | (~gt1_f & ~lt1_f & lt0_f);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= cmp_0;
    end
end
endmodule

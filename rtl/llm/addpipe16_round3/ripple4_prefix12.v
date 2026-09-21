module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg         valid_o,
    output reg  [15:0] y_o
);

wire [3:0] low_sum;
wire [4:0] low_carry;

assign low_carry[0] = 1'b0;

genvar lr;
generate
    for (lr = 0; lr < 4; lr = lr + 1) begin : low_ripple
        assign low_sum[lr] =
            a_i[lr] ^ b_i[lr] ^ low_carry[lr];

        assign low_carry[lr + 1] =
            (a_i[lr] & b_i[lr]) |
            (a_i[lr] & low_carry[lr]) |
            (b_i[lr] & low_carry[lr]);
    end
endgenerate

wire [11:0] p0;
wire [11:0] g0;

assign p0 = a_i[15:4] ^ b_i[15:4];
assign g0 = a_i[15:4] & b_i[15:4];

wire [11:0] p1;
wire [11:0] g1;

genvar s1;
generate
    for (s1 = 0; s1 < 12; s1 = s1 + 1) begin : prefix_1
        if (s1 >= 1) begin
            assign g1[s1] =
                g0[s1] |
                (p0[s1] & g0[s1 - 1]);

            assign p1[s1] =
                p0[s1] &
                p0[s1 - 1];
        end else begin
            assign g1[s1] = g0[s1];
            assign p1[s1] = p0[s1];
        end
    end
endgenerate

wire [11:0] p2;
wire [11:0] g2;

genvar s2;
generate
    for (s2 = 0; s2 < 12; s2 = s2 + 1) begin : prefix_2
        if (s2 >= 2) begin
            assign g2[s2] =
                g1[s2] |
                (p1[s2] & g1[s2 - 2]);

            assign p2[s2] =
                p1[s2] &
                p1[s2 - 2];
        end else begin
            assign g2[s2] = g1[s2];
            assign p2[s2] = p1[s2];
        end
    end
endgenerate

wire [11:0] p4;
wire [11:0] g4;

genvar s4;
generate
    for (s4 = 0; s4 < 12; s4 = s4 + 1) begin : prefix_4
        if (s4 >= 4) begin
            assign g4[s4] =
                g2[s4] |
                (p2[s4] & g2[s4 - 4]);

            assign p4[s4] =
                p2[s4] &
                p2[s4 - 4];
        end else begin
            assign g4[s4] = g2[s4];
            assign p4[s4] = p2[s4];
        end
    end
endgenerate

wire [11:0] p8;
wire [11:0] g8;

genvar s8;
generate
    for (s8 = 0; s8 < 12; s8 = s8 + 1) begin : prefix_8
        if (s8 >= 8) begin
            assign g8[s8] =
                g4[s8] |
                (p4[s8] & g4[s8 - 8]);

            assign p8[s8] =
                p4[s8] &
                p4[s8 - 8];
        end else begin
            assign g8[s8] = g4[s8];
            assign p8[s8] = p4[s8];
        end
    end
endgenerate

wire [12:0] high_carry;
wire [11:0] high_sum;

assign high_carry[0] = low_carry[4];

genvar hc;
generate
    for (hc = 0; hc < 12; hc = hc + 1) begin : high_carries
        assign high_carry[hc + 1] =
            g8[hc] |
            (p8[hc] & high_carry[0]);

        assign high_sum[hc] =
            p0[hc] ^ high_carry[hc];
    end
endgenerate

wire [15:0] sum;

assign sum = {
    high_sum,
    low_sum
};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 16'd0;
    end else begin
        valid_o <= valid_i;

        if (valid_i)
            y_o <= sum;
    end
end

endmodule

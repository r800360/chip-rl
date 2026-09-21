module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg         valid_o,
    output reg  [15:0] y_o
);

wire [7:0] low_sum;
wire [8:0] low_carry;

assign low_carry[0] = 1'b0;

genvar r;
generate
    for (r = 0; r < 8; r = r + 1) begin : low_ripple
        assign low_sum[r] =
            a_i[r] ^ b_i[r] ^ low_carry[r];

        assign low_carry[r + 1] =
            (a_i[r] & b_i[r]) |
            (a_i[r] & low_carry[r]) |
            (b_i[r] & low_carry[r]);
    end
endgenerate


wire [7:0] p0;
wire [7:0] g0;

wire [7:0] p1;
wire [7:0] g1;

wire [7:0] p2;
wire [7:0] g2;

wire [7:0] p4;
wire [7:0] g4;

assign p0 = a_i[15:8] ^ b_i[15:8];
assign g0 = a_i[15:8] & b_i[15:8];


genvar s1;
generate
    for (s1 = 0; s1 < 8; s1 = s1 + 1) begin : prefix_s1
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


genvar s2;
generate
    for (s2 = 0; s2 < 8; s2 = s2 + 1) begin : prefix_s2
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


genvar s4;
generate
    for (s4 = 0; s4 < 8; s4 = s4 + 1) begin : prefix_s4
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


wire [8:0] high_carry;
wire [7:0] high_sum;

assign high_carry[0] = low_carry[8];

genvar h;
generate
    for (h = 0; h < 8; h = h + 1) begin : high_carries
        assign high_carry[h + 1] =
            g4[h] |
            (p4[h] & high_carry[0]);

        assign high_sum[h] =
            p0[h] ^ high_carry[h];
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

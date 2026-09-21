module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg         valid_o,
    output reg  [15:0] y_o
);

wire [7:0] p0;
wire [7:0] g0;

wire [7:0] p1;
wire [7:0] g1;
wire [7:0] p2;
wire [7:0] g2;
wire [7:0] p4;
wire [7:0] g4;

wire [8:0] low_carry;
wire [7:0] low_sum;

wire [8:0] high0;
wire [8:0] high1;
wire [7:0] high_sum;

wire [15:0] sum;

assign p0 = a_i[7:0] ^ b_i[7:0];
assign g0 = a_i[7:0] & b_i[7:0];

genvar i;

generate
    for (i = 0; i < 8; i = i + 1) begin : s1
        if (i >= 1) begin
            assign g1[i] =
                g0[i] | (p0[i] & g0[i-1]);

            assign p1[i] =
                p0[i] & p0[i-1];
        end else begin
            assign g1[i] = g0[i];
            assign p1[i] = p0[i];
        end
    end
endgenerate

generate
    for (i = 0; i < 8; i = i + 1) begin : s2
        if (i >= 2) begin
            assign g2[i] =
                g1[i] | (p1[i] & g1[i-2]);

            assign p2[i] =
                p1[i] & p1[i-2];
        end else begin
            assign g2[i] = g1[i];
            assign p2[i] = p1[i];
        end
    end
endgenerate

generate
    for (i = 0; i < 8; i = i + 1) begin : s4
        if (i >= 4) begin
            assign g4[i] =
                g2[i] | (p2[i] & g2[i-4]);

            assign p4[i] =
                p2[i] & p2[i-4];
        end else begin
            assign g4[i] = g2[i];
            assign p4[i] = p2[i];
        end
    end
endgenerate

assign low_carry[0] = 1'b0;

generate
    for (i = 0; i < 8; i = i + 1) begin : lc
        assign low_carry[i + 1] = g4[i];
    end
endgenerate

assign low_sum = p0 ^ low_carry[7:0];

assign high0 =
    {1'b0, a_i[15:8]}
    +
    {1'b0, b_i[15:8]};

assign high1 =
    {1'b0, a_i[15:8]}
    +
    {1'b0, b_i[15:8]}
    +
    9'd1;

assign high_sum =
    low_carry[8]
    ? high1[7:0]
    : high0[7:0];

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

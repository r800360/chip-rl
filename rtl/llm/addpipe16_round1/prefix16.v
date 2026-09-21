module addpipe16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a_i,
    input  wire [15:0] b_i,
    output reg         valid_o,
    output reg  [15:0] y_o
);

wire [15:0] p0;
wire [15:0] g0;

wire [15:0] p1;
wire [15:0] g1;
wire [15:0] p2;
wire [15:0] g2;
wire [15:0] p4;
wire [15:0] g4;
wire [15:0] p8;
wire [15:0] g8;

wire [16:0] carry;
wire [15:0] sum;

assign p0 = a_i ^ b_i;
assign g0 = a_i & b_i;

genvar i;

generate
    for (i = 0; i < 16; i = i + 1) begin : stage1
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
    for (i = 0; i < 16; i = i + 1) begin : stage2
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
    for (i = 0; i < 16; i = i + 1) begin : stage4
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

generate
    for (i = 0; i < 16; i = i + 1) begin : stage8
        if (i >= 8) begin
            assign g8[i] =
                g4[i] | (p4[i] & g4[i-8]);

            assign p8[i] =
                p4[i] & p4[i-8];
        end else begin
            assign g8[i] = g4[i];
            assign p8[i] = p4[i];
        end
    end
endgenerate

assign carry[0] = 1'b0;

generate
    for (i = 0; i < 16; i = i + 1) begin : carries
        assign carry[i + 1] = g8[i];
    end
endgenerate

assign sum = p0 ^ carry[15:0];

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

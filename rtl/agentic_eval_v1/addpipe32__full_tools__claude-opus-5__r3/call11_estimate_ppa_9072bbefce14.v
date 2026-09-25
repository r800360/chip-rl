module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);
// 4 x 8-bit blocks, block carries via 2-level prefix, carry-select outputs
wire [7:0] pa0 = a_i[7:0],   pb0 = b_i[7:0];
wire [7:0] pa1 = a_i[15:8],  pb1 = b_i[15:8];
wire [7:0] pa2 = a_i[23:16], pb2 = b_i[23:16];
wire [7:0] pa3 = a_i[31:24], pb3 = b_i[31:24];

wire [8:0] u0 = {1'b0,pa0} + {1'b0,pb0};
wire [8:0] v1 = {1'b0,pa1} + {1'b0,pb1};
wire [8:0] w1 = {1'b0,pa1} + {1'b0,pb1} + 9'd1;
wire [8:0] v2 = {1'b0,pa2} + {1'b0,pb2};
wire [8:0] w2 = {1'b0,pa2} + {1'b0,pb2} + 9'd1;
wire [7:0] v3 = pa3 + pb3;
wire [7:0] w3 = pa3 + pb3 + 8'd1;

// group generate / propagate
wire G0 = u0[8];
wire G1 = v1[8];
wire G2 = v2[8];
wire P1 = w1[8];   // block1 propagate (carry out with carry in 1)
wire P2 = w2[8];

wire c1 = G0;
wire c2 = G1 | (P1 & G0);
wire c3 = G2 | (P2 & G1) | (P2 & P1 & G0);

wire [31:0] sum = { c3 ? w3 : v3,
                    c2 ? w2[7:0] : v2[7:0],
                    c1 ? w1[7:0] : v1[7:0],
                    u0[7:0] };

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 32'd0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= sum;
    end
end
endmodule

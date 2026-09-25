module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

// Binary tree priority encoder - 2-level hierarchy
// Level 1: Compare adjacent pairs
wire [4:0] enc[31:0]; // encodes bit position
wire hit[31:0];

// Generate for all bits
genvar i;
generate
for (i = 0; i < 32; i = i + 1) begin : bit_enc
    assign hit[i] = a_i[i];
    assign enc[i] = i;
end
endgenerate

// Level 2a: Pairs
wire [4:0] enc_pair[15:0];
wire hit_pair[15:0];

generate
for (i = 0; i < 16; i = i + 1) begin : pair_enc
    assign hit_pair[i] = hit[2*i+1] | hit[2*i];
    assign enc_pair[i] = hit[2*i+1] ? enc[2*i+1] : enc[2*i];
end
endgenerate

// Level 2b: Quads
wire [4:0] enc_quad[7:0];
wire hit_quad[7:0];

generate
for (i = 0; i < 8; i = i + 1) begin : quad_enc
    assign hit_quad[i] = hit_pair[2*i+1] | hit_pair[2*i];
    assign enc_quad[i] = hit_pair[2*i+1] ? enc_pair[2*i+1] : enc_pair[2*i];
end
endgenerate

// Level 2c: Octets
wire [4:0] enc_octet[3:0];
wire hit_octet[3:0];

generate
for (i = 0; i < 4; i = i + 1) begin : octet_enc
    assign hit_octet[i] = hit_quad[2*i+1] | hit_quad[2*i];
    assign enc_octet[i] = hit_quad[2*i+1] ? enc_quad[2*i+1] : enc_quad[2*i];
end
endgenerate

// Level 2d: Hex (16-bit chunks)
wire [4:0] enc_hex[1:0];
wire hit_hex[1:0];

assign hit_hex[0] = hit_octet[1] | hit_octet[0];
assign enc_hex[0] = hit_octet[1] ? enc_octet[1] : enc_octet[0];
assign hit_hex[1] = hit_octet[3] | hit_octet[2];
assign enc_hex[1] = hit_octet[3] ? enc_octet[3] : enc_octet[2];

// Final result
wire hit_0 = hit_hex[1] | hit_hex[0];
wire [4:0] idx_0 = hit_hex[1] ? enc_hex[1] : enc_hex[0];

wire [5:0] chosen_0 = hit_0 ? {1'b1, idx_0} : 6'd0;

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
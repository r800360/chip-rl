module priority32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [5:0] y_o
);

wire [31:0] s1 = a_i | {1'b0,  a_i[31:1]};
wire [31:0] s2 = s1  | {2'b0,  s1[31:2]};
wire [31:0] s4 = s2  | {4'b0,  s2[31:4]};
wire [31:0] s8 = s4  | {8'b0,  s4[31:8]};
wire [31:0] p  = s8  | {16'b0, s8[31:16]};
wire [31:0] oh = p & ~{1'b0, p[31:1]};

wire [5:0] chosen_0 = { p[0],
                        |(oh & 32'hFFFF0000),
                        |(oh & 32'hFF00FF00),
                        |(oh & 32'hF0F0F0F0),
                        |(oh & 32'hCCCCCCCC),
                        |(oh & 32'hAAAAAAAA) };

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
module addpipe32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    output reg         valid_o,
    output reg  [31:0] y_o
);

    // 4-way 8-bit carry-select adder
    wire [8:0] s0 = {1'b0, a_i[7:0]}  + {1'b0, b_i[7:0]};
    wire       c0 = s0[8];

    wire [7:0] s1a = a_i[15:8] + b_i[15:8];
    wire [7:0] s1b = a_i[15:8] + b_i[15:8] + 8'd1;
    wire [7:0] s1  = c0 ? s1b : s1a;
    wire       c1  = c0 ? (({1'b0,a_i[15:8]} + {1'b0,b_i[15:8]} + 9'd1) >> 8) :
                            (({1'b0,a_i[15:8]} + {1'b0,b_i[15:8]}) >> 8);

    wire [7:0] s2a = a_i[23:16] + b_i[23:16];
    wire [7:0] s2b = a_i[23:16] + b_i[23:16] + 8'd1;
    wire [7:0] s2  = c1 ? s2b : s2a;
    wire       c2  = c1 ? (({1'b0,a_i[23:16]} + {1'b0,b_i[23:16]} + 9'd1) >> 8) :
                            (({1'b0,a_i[23:16]} + {1'b0,b_i[23:16]}) >> 8);

    wire [7:0] s3a = a_i[31:24] + b_i[31:24];
    wire [7:0] s3b = a_i[31:24] + b_i[31:24] + 8'd1;
    wire [7:0] s3  = c2 ? s3b : s3a;

    wire [31:0] sum = {s3, s2, s1, s0[7:0]};

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

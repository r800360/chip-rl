module addpipe (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid_i,
    input  wire [7:0] a_i,
    input  wire [7:0] b_i,
    output reg        valid_o,
    output reg  [7:0] y_o
);


wire [2:0] s0;
wire [2:0] s1;
wire [2:0] s2;
wire [2:0] s3;

wire [7:0] sum;

assign s0 = {1'b0, a_i[1:0]}
          + {1'b0, b_i[1:0]};

assign s1 = {1'b0, a_i[3:2]}
          + {1'b0, b_i[3:2]}
          + s0[2];

assign s2 = {1'b0, a_i[5:4]}
          + {1'b0, b_i[5:4]}
          + s1[2];

assign s3 = {1'b0, a_i[7:6]}
          + {1'b0, b_i[7:6]}
          + s2[2];

assign sum = {
    s3[1:0],
    s2[1:0],
    s1[1:0],
    s0[1:0]
};

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o     <= 8'd0;
    end else begin

        valid_o <= valid_i;
        y_o <= sum;

    end
end

endmodule

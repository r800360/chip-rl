module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

// four 8-bit slices compared independently (shallow, ABC-optimised)
wire l0 = (a_i[7:0]   < b_i[7:0]);
wire l1 = (a_i[15:8]  < b_i[15:8]);
wire l2 = (a_i[23:16] < b_i[23:16]);
wire l3 = (a_i[31:24] < b_i[31:24]);
wire q0 = (a_i[7:0]   == b_i[7:0]);
wire q1 = (a_i[15:8]  == b_i[15:8]);
wire q2 = (a_i[23:16] == b_i[23:16]);
wire q3 = (a_i[31:24] == b_i[31:24]);

// pre-computed early terms (off the critical path)
wire s3  = valid_i & q3;
wire s32 = valid_i & q3 & q2;
wire s31 = valid_i & q3 & q2 & q1;

// top merge with the enable mux folded in: one AND + one OR from each late l*
wire y_next = (valid_i & l3) | (s3 & l2) | (s32 & l1) | (s31 & l0) | (~valid_i & y_o);

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= 1'd0;
    end else begin
        valid_o <= valid_i;
        y_o <= y_next;
    end
end
endmodule

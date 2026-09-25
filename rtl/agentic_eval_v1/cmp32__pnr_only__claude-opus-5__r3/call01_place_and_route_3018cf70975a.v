module cmp32 (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [0:0] y_o
);

wire [31:0] e = ~(a_i ^ b_i);
wire [31:0] g = (~a_i) & b_i;

// ---- 8 groups of 4 bits ----
wire [7:0] lg, eg;

assign lg[0] = g[3] | (e[3] & g[2]) | (e[3] & e[2] & g[1]) | (e[3] & e[2] & e[1] & g[0]);
assign eg[0] = e[3] & e[2] & e[1] & e[0];
assign lg[1] = g[7] | (e[7] & g[6]) | (e[7] & e[6] & g[5]) | (e[7] & e[6] & e[5] & g[4]);
assign eg[1] = e[7] & e[6] & e[5] & e[4];
assign lg[2] = g[11] | (e[11] & g[10]) | (e[11] & e[10] & g[9]) | (e[11] & e[10] & e[9] & g[8]);
assign eg[2] = e[11] & e[10] & e[9] & e[8];
assign lg[3] = g[15] | (e[15] & g[14]) | (e[15] & e[14] & g[13]) | (e[15] & e[14] & e[13] & g[12]);
assign eg[3] = e[15] & e[14] & e[13] & e[12];
assign lg[4] = g[19] | (e[19] & g[18]) | (e[19] & e[18] & g[17]) | (e[19] & e[18] & e[17] & g[16]);
assign eg[4] = e[19] & e[18] & e[17] & e[16];
assign lg[5] = g[23] | (e[23] & g[22]) | (e[23] & e[22] & g[21]) | (e[23] & e[22] & e[21] & g[20]);
assign eg[5] = e[23] & e[22] & e[21] & e[20];
assign lg[6] = g[27] | (e[27] & g[26]) | (e[27] & e[26] & g[25]) | (e[27] & e[26] & e[25] & g[24]);
assign eg[6] = e[27] & e[26] & e[25] & e[24];
assign lg[7] = g[31] | (e[31] & g[30]) | (e[31] & e[30] & g[29]) | (e[31] & e[30] & e[29] & g[28]);
assign eg[7] = e[31] & e[30] & e[29] & e[28];

// ---- merge to 4 ----
wire [3:0] lp, ep;
assign lp[0] = lg[1] | (eg[1] & lg[0]);  assign ep[0] = eg[1] & eg[0];
assign lp[1] = lg[3] | (eg[3] & lg[2]);  assign ep[1] = eg[3] & eg[2];
assign lp[2] = lg[5] | (eg[5] & lg[4]);  assign ep[2] = eg[5] & eg[4];
assign lp[3] = lg[7] | (eg[7] & lg[6]);  assign ep[3] = eg[7] & eg[6];

// ---- merge to 2 ----
wire [1:0] lq, eq;
assign lq[0] = lp[1] | (ep[1] & lp[0]);  assign eq[0] = ep[1] & ep[0];
assign lq[1] = lp[3] | (ep[3] & lp[2]);  assign eq[1] = ep[3] & ep[2];

// ---- top level merged with the enable mux ----
wire y_next = (valid_i & lq[1]) | (valid_i & eq[1] & lq[0]) | (~valid_i & y_o);

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

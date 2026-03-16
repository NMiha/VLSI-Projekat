module register #(parameter DATA_WIDTH = 16, parameter HIGH = DATA_WIDTH - 1) 
(
    input clk,
    input rst_n,
    input cl,
    input ld,
    input [HIGH:0] in,
    input inc,
    input dec,
    input sr,
    input ir,
    input sl,
    input il,
    output [HIGH:0] out
);

    reg [HIGH:0] out_reg, out_next;

    assign out = out_reg;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            out_reg <= 16'h0000;
        else
            out_reg <= out_next; 
    end

    always @(*) begin
        casex ({cl, ld, inc, dec, sr, sl})
            6'b1xxxxx: out_next <= 16'h0000;
            6'b01xxxx: out_next <= in;
            6'b001xxx: out_next <= out_reg + 16'h0001;
            6'b0001xx: out_next <= out_reg - 16'h0001;
            6'b00001x: out_next <= {ir, {15{1'b0}}} | (out_reg >> 1);
            6'b000001: out_next <= {{15{1'b0}}, il} | (out_reg << 1);
            6'b000000: out_next <= out_reg;
        endcase
    end
    
endmodule
module register (
    input clk,
    input rst_n,
    input cl,
    input ld,
    input [3:0] in,
    input inc,
    input dec,
    input sr,
    input ir,
    input sl,
    input il,
    output [3:0] out
);

    reg [3:0] out_reg, out_next;

    assign out = out_reg;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            out_reg <= 4'b0000;
        else
            out_reg <= out_next; 
    end

    always @(*) begin
        casex ({cl, ld, inc, dec, sr, sl})
            6'b1xxxxx: out_next <= 4'h0;
            6'b01xxxx: out_next <= in;
            6'b001xxx: out_next <= out_reg + 4'h1;
            6'b0001xx: out_next <= out_reg - 4'h1;
            6'b00001x: out_next <= {ir, {3{1'b0}}} | (out_reg >> 1);
            6'b000001: out_next <= {{3{1'b0}}, il} | (out_reg << 1);
            6'b000000: out_next <= out_reg;
        endcase
    end
    
endmodule
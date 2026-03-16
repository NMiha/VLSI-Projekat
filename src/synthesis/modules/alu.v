module alu #(parameter DATA_WIDTH = 16, parameter  HIGH = DATA_WIDTH - 1) 
(
    input [2:0] oc,
    input [HIGH:0] a,
    input [HIGH:0] b,
    output [HIGH:0] f
);

    reg [HIGH:0] result;

    assign f = result;

    always @(*) begin 
        case(oc)
            3'b000: result = a + b;    // ADD
            3'b001: result = a - b;    // SUB
            3'b010: result = a * b;    // MUL
            3'b011: result = a / b;    // DIV
            3'b100: result = ~a;       // NOT
            3'b101: result = a ^ b;    // XOR
            3'b110: result = a | b;    // OR
            3'b111: result = a & b;    // AND
            default: result = 16'h0000; // Default case
        endcase
    end
    
endmodule
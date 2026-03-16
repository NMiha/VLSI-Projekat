module clk_div #(parameter DIVISOR = 50_000_000) 
(
    input clk,
    input rst_n,
    output reg out
);

    integer counter;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            counter <= 0;
            out <=0;
        end else begin
            if(counter == DIVISOR / 2 - 1) begin
                out <= ~out;
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
    end
    
endmodule
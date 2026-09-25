// ============================================================================
//  color_codes - dvocifreni broj `num` (0..63) -> boje dveju cifara `code`
//  Visih 12 bita = boja cifre DESETICA, nizih 12 bita = boja cifre JEDINICA.
//  12-bitna boja je {R[3:0], G[3:0], B[3:0]} (Tabela 11).
// ============================================================================
module color_codes (
    input  [5:0]  num,
    output [23:0] code
);
    wire [3:0] tens = num / 4'd10;
    wire [3:0] ones = num % 4'd10;

    function [11:0] color;
        input [3:0] d;
        case (d)
            4'd0: color = 12'h000;  // crna
            4'd1: color = 12'hF00;  // crvena
            4'd2: color = 12'hF80;  // narandzasta
            4'd3: color = 12'hFF0;  // zuta
            4'd4: color = 12'h0F0;  // zelena
            4'd5: color = 12'h0FF;  // cijan
            4'd6: color = 12'h08F;  // svetloplava
            4'd7: color = 12'h00F;  // plava
            4'd8: color = 12'hF0F;  // magenta
            4'd9: color = 12'hFFF;  // bela
            default: color = 12'h000;
        endcase
    endfunction

    assign code = {color(tens), color(ones)};
endmodule

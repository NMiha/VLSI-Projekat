// ============================================================================
//  scan_codes - prevodi pritisak (otpustanje) tastera-cifre u broj `num`
//
//  Prati ISKLJUCIVO otpustanje tastera (break kod: tastatura salje 0xF0 pa
//  skenkod), i ISKLJUCIVO tastere cifara 0-9.  Prevodi samo kada je status=1
//  (procesor spreman/ceka).  control postaje 1 kada je nov broj preveden i
//  ostaje 1 sve dok status ne padne na 0 (handshake sa procesorom).
//  Radi na brzom taktu; status/control/num su nivoi ka sporom procesoru.
// ============================================================================
module scan_codes (
    input            clk,
    input            rst_n,
    input     [15:0] code,     // poslednja dva bajta sa tastature (iz ps2)
    input            status,   // procesor spreman da primi (iz cpu)
    output reg       control,  // nov broj spreman (ka cpu)
    output reg [3:0] num       // prevedena cifra
);
    // --- dekodovanje skenkoda cifre (PS/2 Set 2) ---
    reg [3:0] dig;
    reg       valid;
    always @(*) begin
        valid = 1'b1;
        case (code[7:0])
            8'h45: dig = 4'd0;
            8'h16: dig = 4'd1;
            8'h1E: dig = 4'd2;
            8'h26: dig = 4'd3;
            8'h25: dig = 4'd4;
            8'h2E: dig = 4'd5;
            8'h36: dig = 4'd6;
            8'h3D: dig = 4'd7;
            8'h3E: dig = 4'd8;
            8'h46: dig = 4'd9;
            default: begin dig = 4'd0; valid = 1'b0; end
        endcase
    end

    // --- sveze otpustanje cifre: code se promenio i gornji bajt je 0xF0 (break) ---
    reg [15:0] code_prev;
    wire release_evt = (code != code_prev) && (code[15:8] == 8'hF0) && valid;

    // --- handshake automat ---
    localparam S_WAIT = 1'b0, S_READY = 1'b1;
    reg state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_WAIT;
            control   <= 1'b0;
            num       <= 4'd0;
            code_prev <= 16'd0;
        end else begin
            code_prev <= code;
            case (state)
                S_WAIT: begin
                    control <= 1'b0;
                    if (status && release_evt) begin  // prevodi samo kad je procesor spreman
                        num     <= dig;
                        control <= 1'b1;              // javi da ima nov broj
                        state   <= S_READY;
                    end
                end
                S_READY: begin
                    control <= 1'b1;                  // drzi control dok status ne padne
                    if (!status) begin
                        control <= 1'b0;
                        state   <= S_WAIT;
                    end
                end
            endcase
        end
    end
endmodule

// ============================================================================
//  ps2 - kontroler za PS/2 tastaturu
//  Prima serijski tok sa tastature (start, 8 data LSB-first, parity, stop),
//  sklapa bajtove i u `code` cuva poslednja dva: poslednji na [7:0],
//  pretposlednji na [15:8].  Radi na brzom (sistemskom) taktu.
// ============================================================================
module ps2 (
    input             clk,
    input             rst_n,
    input             ps2_clk,     // takt tastature
    input             ps2_data,    // serijski podatak tastature
    output reg [15:0] code
);
    // --- sinhronizacija ps2_clk na sistemski takt + opadajuca ivica ---
    reg [2:0] sync;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) sync <= 3'b111;
        else        sync <= {sync[1:0], ps2_clk};
    wire fall = sync[2] & ~sync[1];   // ps2_clk: 1 -> 0 (tada je podatak validan)

    // --- prihvatni pomeracki registar i brojac bita ---
    reg [3:0]  cnt;      // 0..10 (11 bita po okviru)
    reg [10:0] shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt   <= 4'd0;
            shift <= 11'd0;
            code  <= 16'h0000;
        end else if (fall) begin
            shift <= {ps2_data, shift[10:1]};   // ubaci novi bit na vrh (LSB-first)
            if (cnt == 4'd10) begin              // upravo stigao 11. bit (stop)
                code <= {code[7:0], shift[9:2]}; // novi bajt na [7:0], stari na [15:8]
                cnt  <= 4'd0;
            end else begin
                cnt  <= cnt + 1'b1;
            end
        end
    end
endmodule

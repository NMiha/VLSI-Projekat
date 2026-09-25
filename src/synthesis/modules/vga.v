// ============================================================================
//  vga - VGA kontroler (640x480 @ 60Hz, pikselski takt 25MHz iz 50MHz)
//  Leva polovina ekrana prikazuje boju code[23:12], desna code[11:0].
//  hsync/vsync su aktivni na nuli.
// ============================================================================
module vga (
    input             clk,
    input             rst_n,
    input      [23:0] code,
    output reg        hsync,
    output reg        vsync,
    output reg [3:0]  red,
    output reg [3:0]  green,
    output reg [3:0]  blue
);
    // --- pikselski takt: 25MHz = svaki drugi ciklus 50MHz ---
    reg pix;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) pix <= 1'b0;
        else        pix <= ~pix;

    // --- brojaci piksela (640+160 = 800 horizontalno, 480+45 = 525 vertikalno) ---
    reg [9:0] h_cnt, v_cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= 10'd0;
            v_cnt <= 10'd0;
        end else if (pix) begin
            if (h_cnt == 10'd799) begin
                h_cnt <= 10'd0;
                v_cnt <= (v_cnt == 10'd524) ? 10'd0 : (v_cnt + 1'b1);
            end else begin
                h_cnt <= h_cnt + 1'b1;
            end
        end
    end

    wire        visible = (h_cnt < 10'd640) && (v_cnt < 10'd480);
    wire [11:0] col     = (h_cnt < 10'd320) ? code[23:12] : code[11:0];  // leva/desna polovina

    always @(*) begin
        // sinhronizacija (aktivno na nuli)
        hsync = ~((h_cnt >= 10'd656) && (h_cnt <= 10'd751));   // sync puls 96 px
        vsync = ~((v_cnt >= 10'd490) && (v_cnt <= 10'd491));   // sync puls 2 linije
        // boja samo u vidljivom delu
        if (visible) begin
            red   = col[11:8];
            green = col[7:4];
            blue  = col[3:0];
        end else begin
            red   = 4'd0;
            green = 4'd0;
            blue  = 4'd0;
        end
    end
endmodule

// ============================================================================
//  top - glavna sema (Sinteza 2)
//  Ulaz: tastatura (ps2 -> scan_codes -> cpu, blokirajuci IN preko control/status)
//  Izlaz: monitor (cpu -> color_codes -> vga -> mnt), diode i displeji.
//  Memorija i procesor rade na usporenom taktu; ps2/scan_codes/vga na 50MHz.
// ============================================================================
module top #(
    parameter DIVISOR    = 50000000,
    parameter FILE_NAME  = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
)(
    input         clk,
    input         rst_n,
    input  [1:0]  kbd,      // kbd[0]=ps2_clk (takt tastature), kbd[1]=ps2_data
    input  [2:0]  btn,      // neiskorisceno u ovoj semi
    input  [8:0]  sw,       // sw se vise ne koristi za unos (ulaz je tastatura)
    output [13:0] mnt,      // {hsync, vsync, red[3:0], green[3:0], blue[3:0]}
    output [9:0]  led,
    output [27:0] hex
);
    // --- usporeni takt (memorija + procesor) ---
    wire slow_clk;
    clk_div #(.DIVISOR(DIVISOR)) u_clk_div (
        .clk(clk), .rst_n(rst_n), .out(slow_clk)
    );

    // --- veze procesor <-> memorija ---
    wire                  cpu_we;
    wire [ADDR_WIDTH-1:0] cpu_addr;
    wire [DATA_WIDTH-1:0] cpu_data, mem_out, cpu_out;
    wire [ADDR_WIDTH-1:0] pc, sp;

    // --- veze tastatura ---
    wire [15:0] kbd_code;
    wire [3:0]  num;
    wire        control, status;

    // --- veze monitor ---
    wire [23:0] color;
    wire        vga_hs, vga_vs;
    wire [3:0]  vga_r, vga_g, vga_b;

    // --- memorija ---
    memory #(
        .FILE_NAME(FILE_NAME), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)
    ) u_mem (
        .clk(slow_clk),
        .we(cpu_we), .addr(cpu_addr), .data(cpu_data), .out(mem_out)
    );

    // --- procesor ---
    cpu #(
        .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)
    ) u_cpu (
        .clk(slow_clk), .rst_n(rst_n),
        .mem(mem_out),
        .in({{(DATA_WIDTH-4){1'b0}}, num}),   // standardni ulaz = cifra sa tastature
        .control(control), .status(status),
        .we(cpu_we), .addr(cpu_addr), .data(cpu_data),
        .out(cpu_out),
        .pc(pc), .sp(sp)
    );

    // --- tastatura: ps2 -> scan_codes (na brzom taktu) ---
    ps2 u_ps2 (
        .clk(clk), .rst_n(rst_n),
        .ps2_clk(kbd[0]), .ps2_data(kbd[1]),
        .code(kbd_code)
    );
    scan_codes u_scan (
        .clk(clk), .rst_n(rst_n),
        .code(kbd_code), .status(status),
        .control(control), .num(num)
    );

    // --- monitor: cpu.out -> color_codes -> vga ---
    color_codes u_col (
        .num(cpu_out[5:0]), .code(color)
    );
    vga u_vga (
        .clk(clk), .rst_n(rst_n), .code(color),
        .hsync(vga_hs), .vsync(vga_vs),
        .red(vga_r), .green(vga_g), .blue(vga_b)
    );
    assign mnt = {vga_hs, vga_vs, vga_r, vga_g, vga_b};

    // --- diode: led[4:0]=izlaz, led[5]=status (spreman za unos) ---
    assign led = {4'b0000, status, cpu_out[4:0]};

    // --- prikaz PC i SP na sedmosegmentnim displejima ---
    wire [3:0] pc_ones, pc_tens, sp_ones, sp_tens;

    bcd u_bcd_pc (.in(pc), .ones(pc_ones), .tens(pc_tens));
    ssd u_ssd_pc0(.in(pc_ones), .out(hex[6:0]));
    ssd u_ssd_pc1(.in(pc_tens), .out(hex[13:7]));

    bcd u_bcd_sp (.in(sp), .ones(sp_ones), .tens(sp_tens));
    ssd u_ssd_sp0(.in(sp_ones), .out(hex[20:14]));
    ssd u_ssd_sp1(.in(sp_tens), .out(hex[27:21]));

endmodule

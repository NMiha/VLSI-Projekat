module top;

    reg clk, rst_n, cl, ld, inc, dec, sr, sl, ir, il;
    reg [2:0] oc;
    reg [3:0] a, b, in;
    wire [3:0] out_alu, out_reg;

    integer i, j, k;

    alu alu1(.oc(oc), .a(a), .b(b), .f(out_alu));

    register register1( .clk(clk), .rst_n(rst_n), .cl(cl), .ld(ld),
                        .inc(inc), .dec(dec), .sr(sr), .sl(sl), .ir(ir),
                        .il(il), .in(in), .out(out_reg));

    initial begin
        // ALU
        oc = 3'b000;
        a = 4'h0;
        b = 4'h0;

        // REGISTER
        clk = 1'b0;
        rst_n = 1'b0;
        cl = 1'b0;
        ld = 1'b0;
        inc = 1'b0;
        dec = 1'b0;
        sr = 1'b0;
        sl = 1'b0;
        ir = 1'b0;
        il = 1'b0;
        in = 4'h0;

        #2 rst_n = 1'b1;

        for(i=0; i<2048; i=i+1) begin
            {oc, a, b} = i;
            #1;
        end

        $stop;
        #3000;

        repeat(1000) begin
            cl = {$random} % 2;
            ld = {$random} % 2;
            inc = {$random} % 2;
            dec = {$random} % 2;
            sr = {$random} % 2;
            sl = {$random} % 2;
            ir = {$random} % 2;
            il = {$random} % 2;
            in = {$random} % 2;
            #10;
        end

        #10 $finish;
    end

    always @(out_alu) begin
        $display("TIME: %4d, oc: %b, a: %b, b: %b, out: %b", $time, oc, a, b, out_alu);
    end

    always @(out_reg) begin
        $display("TIME: %4d, cl: %b, ld: %b, inc: %b, dec: %b, sr: %b, sl: %b, ir: %b, il: %b, in: %b, out: %b",
        $time, cl, ld, inc, dec, sr, sl, ir, il, in, out_reg);
    end

    always
        #5 clk = ~clk;
    
endmodule

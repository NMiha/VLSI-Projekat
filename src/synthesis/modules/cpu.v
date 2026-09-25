// ============================================================================
//  cpu - picoComputer (Konacni automati 2)
//  Dodati portovi `control` (ulaz) i `status` (izlaz); IN je sada BLOKIRAJUCA:
//  status=1 znaci "procesor spreman/ceka unos", a `in` se ucitava kada
//  control=1 (npr. kad scan_codes prevede novu cifru).
// ============================================================================
module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
)(
    input                       clk,
    input                       rst_n,
    input      [DATA_WIDTH-1:0] mem,
    input      [DATA_WIDTH-1:0] in,
    input                       control,    // nov podatak na ulazu (od scan_codes)
    output reg                  status,     // procesor spreman/ceka unos (ka scan_codes)
    output reg                  we,
    output     [ADDR_WIDTH-1:0] addr,
    output     [DATA_WIDTH-1:0] data,
    output     [DATA_WIDTH-1:0] out,
    output     [ADDR_WIDTH-1:0] pc,
    output     [ADDR_WIDTH-1:0] sp
);

    localparam [4:0]
        INIT        = 5'd0,
        FE_ADDR     = 5'd1,
        FE_PRESENT  = 5'd2,
        FE_CAP      = 5'd3,
        R_EA0       = 5'd4,
        IND_PRESENT = 5'd5,
        IND_CAP     = 5'd6,
        RD_PRESENT  = 5'd7,
        RD_CAP      = 5'd8,
        WR0         = 5'd9,
        MOV_S2      = 5'd10,
        ARITH_S2    = 5'd11,
        EX_ALU      = 5'd12,
        IN_WAIT     = 5'd13,   // blokirajuce cekanje na control
        OUT_FIN     = 5'd14,
        ST_X        = 5'd15,
        ST_XO       = 5'd16,
        ST_Y        = 5'd17,
        ST_YO       = 5'd18,
        ST_Z        = 5'd19,
        ST_ZO       = 5'd20,
        HALT        = 5'd21;

    localparam [1:0] OPX = 2'd0, OPY = 2'd1, OPZ = 2'd2;
    localparam [1:0] DST_A = 2'd0, DST_MDR = 2'd1, DST_OUT = 2'd2;
    localparam       MREAD = 1'b0, MWRITE = 1'b1;

    reg  [4:0] state, next_state;
    reg  [1:0] opsel_r, opsel_next;
    reg  [1:0] dst_r,   dst_next;
    reg        mode_r,  mode_next;
    reg  [4:0] ret_r,   ret_next;
    reg  [DATA_WIDTH-1:0] out_r, out_next;

    reg                   pc_cl, pc_ld, pc_inc, pc_dec;
    reg  [ADDR_WIDTH-1:0] pc_in;
    reg                   sp_cl, sp_ld, sp_inc, sp_dec;
    reg  [ADDR_WIDTH-1:0] sp_in;
    reg                   mar_ld;
    reg  [ADDR_WIDTH-1:0] mar_in;
    reg                   mdr_ld;
    reg  [DATA_WIDTH-1:0] mdr_in;
    reg                   a_cl, a_ld;
    reg  [DATA_WIDTH-1:0] a_in;
    reg                   ir_cl, ir_ld;
    reg  [31:0]           ir_in;

    wire [ADDR_WIDTH-1:0] pc_out, sp_out, mar_out;
    wire [DATA_WIDTH-1:0] mdr_out, a_out;
    wire [31:0]           ir;

    wire [3:0] op  = ir[15:12];
    wire [3:0] mop = mem[15:12];
    reg        cur_di;
    reg  [2:0] cur_a;
    always @(*) begin
        case (opsel_r)
            OPX:     begin cur_di = ir[11]; cur_a = ir[10:8]; end
            OPY:     begin cur_di = ir[7];  cur_a = ir[6:4];  end
            OPZ:     begin cur_di = ir[3];  cur_a = ir[2:0];  end
            default: begin cur_di = 1'b0;   cur_a = 3'd0;     end
        endcase
    end

    wire [2:0]            alu_oc = op[2:0] - 3'd1;
    wire [DATA_WIDTH-1:0] alu_f;

    alu #(.DATA_WIDTH(DATA_WIDTH)) u_alu (
        .oc(alu_oc), .a(a_out), .b(mdr_out), .f(alu_f)
    );
    register #(.DATA_WIDTH(ADDR_WIDTH)) u_pc (
        .clk(clk), .rst_n(rst_n), .cl(pc_cl), .ld(pc_ld), .in(pc_in),
        .inc(pc_inc), .dec(pc_dec), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(pc_out)
    );
    register #(.DATA_WIDTH(ADDR_WIDTH)) u_sp (
        .clk(clk), .rst_n(rst_n), .cl(sp_cl), .ld(sp_ld), .in(sp_in),
        .inc(sp_inc), .dec(sp_dec), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(sp_out)
    );
    register #(.DATA_WIDTH(ADDR_WIDTH)) u_mar (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(mar_ld), .in(mar_in),
        .inc(1'b0), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(mar_out)
    );
    register #(.DATA_WIDTH(DATA_WIDTH)) u_mdr (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(mdr_ld), .in(mdr_in),
        .inc(1'b0), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(mdr_out)
    );
    register #(.DATA_WIDTH(DATA_WIDTH)) u_a (
        .clk(clk), .rst_n(rst_n), .cl(a_cl), .ld(a_ld), .in(a_in),
        .inc(1'b0), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(a_out)
    );
    register #(.DATA_WIDTH(32)) u_ir (
        .clk(clk), .rst_n(rst_n), .cl(ir_cl), .ld(ir_ld), .in(ir_in),
        .inc(1'b0), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(ir)
    );

    assign addr = mar_out;
    assign data = a_out;
    assign out  = out_r;
    assign pc   = pc_out;
    assign sp   = sp_out;

    always @(*) begin
        pc_cl=0; pc_ld=0; pc_inc=0; pc_dec=0; pc_in={ADDR_WIDTH{1'b0}};
        sp_cl=0; sp_ld=0; sp_inc=0; sp_dec=0; sp_in={ADDR_WIDTH{1'b0}};
        mar_ld=0; mar_in={ADDR_WIDTH{1'b0}};
        mdr_ld=0; mdr_in={DATA_WIDTH{1'b0}};
        a_cl=0; a_ld=0; a_in={DATA_WIDTH{1'b0}};
        ir_cl=0; ir_ld=0; ir_in=32'd0;
        we=1'b0;
        status=1'b0;                        // podrazumevano: nismo spremni za unos

        next_state = state;
        opsel_next = opsel_r; dst_next = dst_r; mode_next = mode_r;
        ret_next   = ret_r;   out_next = out_r;

        case (state)
            INIT: begin
                pc_ld=1'b1; pc_in=6'd8;
                sp_ld=1'b1; sp_in=6'd63;
                next_state = FE_ADDR;
            end

            FE_ADDR: begin
                mar_ld=1'b1; mar_in=pc_out;
                next_state = FE_PRESENT;
            end
            FE_PRESENT: next_state = FE_CAP;
            FE_CAP: begin
                ir_ld=1'b1; ir_in={16'b0, mem};
                case (mop)
                    4'b0000: begin opsel_next=OPY; dst_next=DST_A;   mode_next=MREAD; ret_next=MOV_S2;   next_state=R_EA0; end
                    4'b0001,
                    4'b0010,
                    4'b0011: begin opsel_next=OPY; dst_next=DST_A;   mode_next=MREAD; ret_next=ARITH_S2; next_state=R_EA0; end
                    4'b0100: begin pc_inc=1'b1; next_state=FE_ADDR; end    // DIV NOP -> PC++
                    4'b0111: next_state=IN_WAIT;                            // IN (blokirajuca)
                    4'b1000: begin opsel_next=OPX; dst_next=DST_OUT; mode_next=MREAD; ret_next=OUT_FIN;  next_state=R_EA0; end
                    4'b1111: next_state=ST_X;
                    default: next_state=HALT;
                endcase
            end

            R_EA0: begin
                mar_ld=1'b1; mar_in={{(ADDR_WIDTH-3){1'b0}}, cur_a};
                if (cur_di==1'b0)
                    next_state = (mode_r==MWRITE) ? WR0 : RD_PRESENT;
                else
                    next_state = IND_PRESENT;
            end
            IND_PRESENT: next_state = IND_CAP;
            IND_CAP: begin
                mar_ld=1'b1; mar_in=mem[ADDR_WIDTH-1:0];
                next_state = (mode_r==MWRITE) ? WR0 : RD_PRESENT;
            end

            RD_PRESENT: next_state = RD_CAP;
            RD_CAP: begin
                case (dst_r)
                    DST_A:   begin a_ld=1'b1;   a_in=mem;   end
                    DST_MDR: begin mdr_ld=1'b1; mdr_in=mem; end
                    default: out_next = mem;                 // DST_OUT
                endcase
                next_state = ret_r;
            end

            WR0: begin
                we=1'b1;
                pc_inc=1'b1;
                next_state = ret_r;
            end

            MOV_S2:  begin opsel_next=OPX; mode_next=MWRITE; ret_next=FE_ADDR; next_state=R_EA0; end
            ARITH_S2:begin opsel_next=OPZ; dst_next=DST_MDR; mode_next=MREAD;  ret_next=EX_ALU;  next_state=R_EA0; end
            EX_ALU:  begin a_ld=1'b1; a_in=alu_f; opsel_next=OPX; mode_next=MWRITE; ret_next=FE_ADDR; next_state=R_EA0; end

            // ---- IN: blokirajuca preko control/status ----
            IN_WAIT: begin
                status = 1'b1;                     // signaliziraj da smo spremni da primimo
                if (control) begin                 // stigao nov podatak
                    a_ld=1'b1; a_in=in;            // ucitaj standardni ulaz u A
                    opsel_next=OPX; mode_next=MWRITE; ret_next=FE_ADDR; next_state=R_EA0;
                end 
                else
                    next_state=IN_WAIT;            // blokiraj dok control!=1
            end
            

            OUT_FIN: begin
                pc_inc=1'b1;
                next_state = FE_ADDR;
            end

            ST_X: begin
                if (ir[11:8]!=4'd0) begin
                    opsel_next=OPX; dst_next=DST_OUT; mode_next=MREAD; ret_next=ST_XO; next_state=R_EA0;
                end else next_state=ST_Y;
            end
            ST_XO: next_state=ST_Y;
            ST_Y: begin
                if (ir[7:4]!=4'd0) begin
                    opsel_next=OPY; dst_next=DST_OUT; mode_next=MREAD; ret_next=ST_YO; next_state=R_EA0;
                end else next_state=ST_Z;
            end
            ST_YO: next_state=ST_Z;
            ST_Z: begin
                if (ir[3:0]!=4'd0) begin
                    opsel_next=OPZ; dst_next=DST_OUT; mode_next=MREAD; ret_next=ST_ZO; next_state=R_EA0;
                end else next_state=HALT;
            end
            ST_ZO: next_state=HALT;

            HALT: next_state = HALT;
            default: next_state = INIT;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= INIT;
            opsel_r <= OPX;
            dst_r   <= DST_A;
            mode_r  <= MREAD;
            ret_r   <= FE_ADDR;
            out_r   <= {DATA_WIDTH{1'b0}};
        end else begin
            state   <= next_state;
            opsel_r <= opsel_next;
            dst_r   <= dst_next;
            mode_r  <= mode_next;
            ret_r   <= ret_next;
            out_r   <= out_next;
        end
    end

endmodule

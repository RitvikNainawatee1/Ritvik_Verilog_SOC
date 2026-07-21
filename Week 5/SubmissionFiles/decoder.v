module decoder(input clk, input rst, input we_imem_in, input [5:0] imem_waddr_in, input [15:0] imem_wdata_inw, input dmem_we_in, input [5:0] dmem_waddr_in, input [7:0] dmem_wdata_in, output [7:0] regs [0:63]);
    parameter fetch = 1'b0, decode = 1'b1;
    parameter OP_LOAD = 6'b000000, OP_CMP = 6'b000001, OP_WRT = 6'b000010, OP_INC = 6'b000011, OP_DEC = 6'b000100, OP_JMP = 6'b000101, OP_LOADI = 6'b000110, OP_WRTI = 6'b000111;

    reg state;
    reg inc_pc, load_pc;
    reg [5:0] pc_load_val, pc_out;

    reg regs_we;
    reg [1:0] regs_waddr;
    reg [7:0] A,B,C,D, regs_wdata;

    reg [7:0] alu_a, alu_b, alu_result;
    reg [2:0] alu_op;
    reg alu_zero, alu_negative, alu_carry, alu_overflow;

    reg we_dmem;
    reg [5:0] dmem_raddr, dmem_waddr;
    reg [7:0] dmem_wdata, dmem_rdata;

    reg [5:0] imem_waddr;  
    reg [15:0] imem_wdata, imem_rdata;

    pc pc(clk, 1'b0, inc_pc, load_pc, pc_load_val, pc_out);
    regfile regfile(clk, rst, regs_we, regs_waddr, regs_wdata, A, B, C, D);
    alu alu(alu_a, alu_b, alu_op, alu_result, alu_zero, alu_carry, alu_overflow, alu_negative);
    dmem dmem(clk, we_dmem, dmem_raddr, dmem_waddr, dmem_wdata, dmem_rdata, regs);
    imem imem(clk, we_imem_in, pc_out, imem_waddr, imem_wdata, imem_rdata);

    reg [15:0] instruction;

    wire [5:0] opcode = instruction[15:10];
    wire [5:0] field_XL = instruction[9:4];   
    wire [1:0] field1 = instruction[3:2];  
    wire [1:0] field2 = instruction[1:0];  
    wire [5:0] jmp_target = instruction[5:0];

    reg [7:0] temp;

    initial begin
        state = fetch;
        instruction = 16'b0;
    end

    function [7:0] reg_select;
        input [1:0] sel;
        input [7:0] ra, rb, rc, rd;
        begin
            case (sel)
                2'b00: reg_select = ra;
                2'b01: reg_select = rb;
                2'b10: reg_select = rc;
                2'b11: reg_select = rd;
                default: reg_select = ra;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if((!we_imem_in) & (!dmem_we_in)) begin
            case(state)
                fetch: begin
                    instruction <= imem_rdata;
                    state <= decode;
                end
                decode: begin
                    state <= fetch;
                end
                default: state <= fetch;
            endcase
        end else if(!(dmem_we_in)) begin
            imem_waddr <= imem_waddr_in;
            imem_wdata <= imem_wdata_inw;
        end else begin
            we_dmem <= dmem_we_in;
            dmem_waddr <= dmem_waddr_in;
            dmem_wdata <= dmem_wdata_in;
        end
    end

    always @(negedge we_imem_in) begin
        load_pc = 1'b1;
        pc_load_val = 5'b0;
    end
    
    always @(*) begin
        if((!we_imem_in) & (!dmem_we_in)) begin
            {inc_pc, load_pc, pc_load_val} = 8'b0;
            {regs_we, regs_waddr, regs_wdata} = 11'b0;
            {we_dmem, dmem_raddr, dmem_waddr, dmem_wdata} = 8'b0;
            {alu_a, alu_b, alu_op} = 19'b0;

            if(state == decode) begin
                case(opcode) 
                    OP_LOAD: begin
                        temp[7:0] = reg_select(field1, A, B, C, D);
                        dmem_raddr = temp[5:0];
                        regs_we = 1'b1;
                        regs_waddr = field2;
                        regs_wdata = dmem_rdata;
                        inc_pc = 1'b1;
                    end

                    OP_LOADI: begin
                        dmem_raddr = field_XL;
                        regs_we = 1'b1;
                        regs_waddr = field2;
                        regs_wdata = dmem_rdata;
                        inc_pc = 1'b1;
                    end

                    OP_CMP: begin
                        alu_a  = reg_select(field1, A, B, C, D);
                        alu_b  = reg_select(field2, A, B, C, D);
                        alu_op = 3'b001;
                        if(alu_carry && !alu_zero) begin
                            load_pc = 1'b1;
                            pc_load_val = field_XL;
                        end 
                        else inc_pc = 1'b1;
                    end

                    OP_WRT: begin
                        dmem_wdata = reg_select(field1, A, B, C, D);
                        temp[7:0] = reg_select(field2, A, B, C, D);
                        dmem_waddr = temp[5:0];
                        we_dmem = 1'b1;
                        inc_pc = 1'b1;
                    end

                    
                    OP_WRTI: begin
                        dmem_wdata = reg_select(field2, A, B, C, D);
                        dmem_waddr = field_XL;
                        we_dmem = 1'b1;
                        inc_pc = 1'b1;
                    end

                    OP_INC: begin
                        alu_a = reg_select(field1, A, B, C, D);
                        alu_b = 8'b00000001;
                        alu_op = 3'b000;
                        regs_we = 1'b1;
                        regs_waddr = field2;
                        regs_wdata = alu_result;
                        inc_pc= 1'b1;
                    end

                    OP_DEC: begin
                        alu_a = reg_select(field1, A, B, C, D);
                        alu_b = 8'b00000001;
                        alu_op = 3'b001;
                        regs_we = 1'b1;
                        regs_waddr = field2;
                        regs_wdata = alu_result;
                        inc_pc= 1'b1;
                    end

                    OP_JMP: begin
                        load_pc = 1'b1;
                        pc_load_val = jmp_target;
                    end

                    default: begin
                        inc_pc = 1'b1;
                    end
                endcase
            end
        end
    end
endmodule

// Hopefully I can assume preloaded:
// 10 contains i and 11 contains i+1 (with actual correct starting points)
// dmem[63] contains the higher memory address of sortable entries
// dmem[62] contains (lower memory address - 1) of sortable entries
// you cannot start at the 0th memory address of dmem just to simplify things for me
// 0. LOAD 10, 00
// 1. LOAD 11, 01
// 2. CMP 110, 00, 01 
// 3. INC 10, 10
// 4. INC 11, 11
// 5. JMP 1010
// 6. WRT 00, 11
// 7. WRT 01, 10
// 8. DEC 10, 10
// 9. DEC 11, 11
// 10. LOADI 111110, 00
// 11. CMP 1111, 10, 00
// 12. INC 10, 10
// 13. INC 11, 11
// 14. JMP 0
// 15. LOADI 111111, 00 
// 16. CMP 10010, 11, 00
// 17. JMP 0
// 18. no-op???

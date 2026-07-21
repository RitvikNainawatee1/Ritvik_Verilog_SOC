module decoder(input clk, input rst, input we_imem_in, input [5:0] imem_waddr_in, input [15:0] imem_wdata_inw, input dmem_we_in, input [5:0] dmem_waddr_in, input [7:0] dmem_wdata_in, output [7:0] regs [0:63]);
    parameter fetch = 3'b000, decode = 3'b001, aluop = 3'b010, mem = 3'b011, regwb = 3'b100;
    parameter OP_LOAD = 6'b000000, OP_CMP = 6'b000001, OP_WRT = 6'b000010, OP_INC = 6'b000011, OP_DEC = 6'b000100, OP_JMP = 6'b000101, OP_LOADI = 6'b000110, OP_WRTI = 6'b000111;

    reg [2:0] state, next_state;
    reg inc_pc, load_pc;
    reg [5:0] pc_load_val;
    wire [5:0] pc_out;

    reg regs_we;
    reg [1:0] regs_waddr;
    reg [7:0] regs_wdata;
    wire [7:0] A,B,C,D;

    reg [7:0] alu_a, alu_b;
    wire [7:0] alu_result;
    reg [2:0] alu_op;
    wire alu_zero, alu_negative, alu_carry, alu_overflow;

    reg we_dmem;
    reg [5:0] dmem_raddr, dmem_waddr;
    reg [7:0] dmem_wdata;
    wire [7:0] dmem_rdata;

    reg [5:0] imem_waddr;  
    reg [15:0] imem_wdata;
    wire [15:0] imem_rdata;

    reg [7:0] alu_result_reg;
    reg [7:0] dmem_rdata_reg;
    reg [5:0] addr_reg;

    pc pc(clk, 1'b0, inc_pc, load_pc, pc_load_val, pc_out);
    regfile regfile(clk, rst, regs_we, regs_waddr, regs_wdata, A, B, C, D);
    alu ALU(alu_a, alu_b, alu_op, alu_result, alu_zero, alu_carry, alu_overflow, alu_negative);
    dmem dmem(clk, we_dmem, dmem_raddr, dmem_waddr, dmem_wdata, dmem_rdata, regs);
    imem imem(clk, we_imem_in, pc_out, imem_waddr, imem_wdata, imem_rdata);

    reg [15:0] instruction;

    wire [5:0] opcode = instruction[15:10];
    wire [5:0] field_XL = instruction[9:4];   
    wire [1:0] field1 = instruction[3:2];  
    wire [1:0] field2 = instruction[1:0];  
    wire [5:0] jmp_target = instruction[5:0];

    reg [7:0] temp_addr;

    initial begin
        state = fetch;
        instruction = 16'b0;
        prev_we_imem_in = 1'b0;
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
            state <= next_state;

            if(state == fetch) instruction <= imem_rdata;
            if(state == aluop) begin
                alu_result_reg <= alu_result;
                if(opcode == OP_WRT) temp_addr <= reg_select(field2, A, B, C, D);
                else temp_addr <= reg_select(field1, A, B, C, D);
            end
            if(state == mem) dmem_rdata_reg <= dmem_rdata;
        end 

        else if(!(dmem_we_in)) {imem_waddr, imem_wdata} <= {imem_waddr_in, imem_wdata_inw};
        else {we_dmem, dmem_waddr, dmem_wdata} <= {dmem_we_in, dmem_waddr_in, dmem_wdata_in};
    end

    reg prev_we_imem_in;
    always @(posedge clk) prev_we_imem_in <= we_imem_in;
    wire imem_load_done = prev_we_imem_in & ~we_imem_in;

    always @(temp_addr) addr_reg = temp_addr[5:0];

    always @(*) begin
        next_state = fetch;

        case(state)
            fetch: next_state = decode;

            decode: case(opcode)
                        OP_CMP, OP_JMP: next_state = fetch;
                        OP_LOADI, OP_WRTI: next_state = mem;
                        default: next_state = aluop;
                    endcase

            aluop: case(opcode)
                    OP_INC, OP_DEC: next_state = regwb;
                    default: next_state = mem;
                endcase

            mem: case(opcode)
                    OP_WRT, OP_WRTI: next_state = fetch;
                    default: next_state = regwb;
                endcase
            
            regwb: next_state = fetch;
        endcase
    end
    
    always @(*) begin
        if((!we_imem_in) & (!dmem_we_in)) begin
            {inc_pc, load_pc, pc_load_val} = 8'b0;
            {regs_we, regs_waddr, regs_wdata} = 11'b0;
            {we_dmem, dmem_raddr, dmem_waddr, dmem_wdata} = 8'b0;
            {alu_a, alu_b, alu_op} = 19'b0;

            if(imem_load_done) begin
                load_pc = 1'b1;
                pc_load_val = 6'b0;
            end

            else begin
                case(state)
                    decode: case(opcode)
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

                                OP_JMP: begin
                                    load_pc = 1'b1;
                                    pc_load_val = jmp_target;
                                end

                                default:;
                            endcase 

                    mem: case(opcode)
                            OP_LOAD: dmem_raddr = addr_reg;
                            OP_LOADI: dmem_raddr = field_XL;

                            OP_WRT: begin
                                we_dmem = 1'b1;
                                dmem_waddr = addr_reg;
                                dmem_wdata = reg_select(field1, A, B, C, D);
                                inc_pc = 1'b1;
                            end

                            OP_WRTI: begin
                                we_dmem = 1'b1;
                                dmem_waddr = field_XL;
                                dmem_wdata = reg_select(field2, A, B, C, D);
                                inc_pc = 1'b1;
                            end
                        endcase

                    aluop: case(opcode)
                        OP_INC: begin
                            alu_a = reg_select(field1, A, B, C, D);
                            alu_b = 8'b00000001;
                            alu_op = 3'b000;
                        end

                        OP_DEC: begin
                            alu_a = reg_select(field1, A, B, C, D);
                            alu_b = 8'b00000001;
                            alu_op = 3'b001; 
                        end

                        default: ;
                    endcase

                    regwb: begin
                        regs_we = 1'b1;
                        regs_waddr = field2;
                        inc_pc = 1'b1;

                        case(opcode)
                            OP_LOAD, OP_LOADI: regs_wdata = dmem_rdata_reg;
                            OP_INC, OP_DEC: regs_wdata = alu_result_reg;
                            default: regs_wdata = 8'b0;
                        endcase
                    end
                endcase
            end
        end
    end
endmodule

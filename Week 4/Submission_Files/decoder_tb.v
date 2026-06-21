`timescale 1ns/1ns

module decoder_tb;
    reg en;
    reg [15:0] instruction;

    wire [15:0] opcode_main;
    wire [3:0] inputs;
    wire [1:0] shifts;
    wire [3:0] brs;

    decoder test(en, instruction, opcode_main, inputs, shifts, brs);

    integer i;

    initial begin
        en = 1;

        for(i=0; i<16; i=i+1) begin
            instruction = 0;
            instruction[15:12] = i;
            
            #10;

            if(opcode_main !== (16'b1 << i)) $display("fail");
            else $display("pass");
        end

        $finish;
    end

    initial begin
        $dumpfile("decoder.vcd");
        $dumpvars(0);
    end

endmodule
module oneToTwo(input en, input w, output reg [1:0] y);
    always @(*) begin
        y = 2'b0;
        y[w] = en? 1'b1 : 1'b0;
    end
endmodule

module twoToFour(input en, input [1:0] w, output reg [3:0] y);
    always @(*) begin
        y = 4'b0;
        y[w] = en? 1'b1 : 1'b0;
    end
endmodule

module fourToSixteen(input en, input [3:0] w, output reg [15:0] y);
    always @(*) begin
        y = 16'b0;
        y[w] = en? 1'b1 : 1'b0;
    end
endmodule

module decoder(input en, input [15:0] instruction, output [15:0] opcode_main, output [3:0] inputs, output [1:0] shifts, output [3:0] brs);
    fourToSixteen mainDecoder(en, instruction[15:12], opcode_main);
    twoToFour inputsDecoder(opcode_main[1], instruction[9:8], inputs);
    twoToFour brsDecoder(opcode_main[15], instruction[9:8], brs);
    oneToTwo shiftsDecoder(opcode_main[12], instruction[8], shifts);
endmodule
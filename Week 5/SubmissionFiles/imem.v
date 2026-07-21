module imem(input clk, input we, input [5:0] raddr, input [5:0] waddr, input [15:0] wdata, output [15:0] rdata);
    reg [15:0] codeMemory [63:0];

    always @(posedge clk) begin
        if(we) codeMemory[waddr] <= wdata;
    end

    assign rdata = codeMemory[raddr];
endmodule

// {6'b000000, 6'bX, 2'bB, 2'bA} -> read from dmem location Q (stored in regfile location B) and load to regfile register A. LOAD
// {6'b000001, 6'bL, 2'bA, 2'bB} -> check if value in regfile location A > regfile location B and if yes go to PC location L. CMP
// {6'b000010, 6'bX, 2'bA, 2'bB} -> write from regfile location A to dmem location Q (stored in regfile location B). WRT
// {6'b000011, 6'bX, 2'bA, 2'bB} -> increment value in regfile location A and store in regfile location B. INC
// {6'b000100, 6'bX, 2'bA, 2'bB} -> decrement vaue in regfile location A and store in regfile location B. DEC
// {6'b000101, 4'bX, 6'bL} -> goto PC location L. JMP
// {6'b000110, 6'bQ, 2'bX, 2'bA} -> Read from dmem location Q and load to regfile register A. LOADI
// {6'b000111, 6'bQ, 2'bX, 2'bA} -> Write from regfile register A to dmem location Q. WRTI 
// {where X means don't care}

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

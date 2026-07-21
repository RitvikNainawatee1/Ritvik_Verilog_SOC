module dmem(input clk, input we, input [5:0] raddr, waddr, input[7:0] wdata, output [7:0] rdata, output reg [7:0] regs [0:63]);
    always @(posedge clk) begin
        if(we) regs[waddr] <= wdata;
    end

    assign rdata = regs[raddr];
endmodule
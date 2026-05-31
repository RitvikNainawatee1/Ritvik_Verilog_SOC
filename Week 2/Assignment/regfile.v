module regfile(input clk, input we, input [1:0] raddr0, raddr1, waddr, input[7:0] wdata, output [7:0] rdata0, output [7:0] rdata1);

    reg [7:0] A,B,C,D;

    initial {A,B,C,D} = 32'b0;

    always @(posedge clk, posedge we) begin
        if(we) begin
            case(waddr) 
                2'b00: A <= wdata;
                2'b01: B <= wdata;
                2'b10: C <= wdata;
                2'b11: D <= wdata;
            endcase
        end
    end

    assign rdata0 = (raddr0[0])? ((raddr0[1])? D : B) : ((raddr0[1])? C : A); 
    assign rdata1 = (raddr1[0])? ((raddr1[1])? D : B) : ((raddr1[1])? C : A); 
endmodule

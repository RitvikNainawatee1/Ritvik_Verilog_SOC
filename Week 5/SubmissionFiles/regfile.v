 module regfile(input clk, input rst, input we, input [1:0] waddr, input[7:0] wdata, output reg [7:0] A, B, C, D);
    always @(posedge clk) begin
        if(we) begin
            if(rst) {A,B,C,D} = 32'b0;
            case(waddr) 
                2'b00: A <= wdata;
                2'b01: B <= wdata;
                2'b10: C <= wdata;
                2'b11: D <= wdata;
                default: ;
            endcase
        end
    end
endmodule
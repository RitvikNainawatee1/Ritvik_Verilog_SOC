module alu (input [7:0] a, b, input[2:0] op, output reg [7:0] result, output zero, output reg carry, output reg overflow, output negative);
    wire [7:0] b_twos_comp = ~b + 1'b1;
    always @(*) begin
        case (op)
            3'b000: begin //add
                {carry, result} = a + b;
                overflow = (a[7]^b[7])? 1'b0 : ((a[7]^result[7])? 1'b1 : 1'b0); 
                //if a and b have opposite sign then overflow not possible otherwise check if sum has same sign as a and b
            end

            3'b001: begin //sub
                {carry, result} = a + b_twos_comp;
                overflow = (a[7]^b[7])? ((a[7]^result[7])? 1'b1 : 1'b0) : 1'b0;
                //if a and b have same sign overflow not possible otherwise check if sum has same sign as a
            end

            3'b010: {result, carry, overflow} = {a&b, 2'b00}; //and
            3'b011: {result, carry, overflow} = {a|b, 2'b00}; //or
            3'b100: {result, carry, overflow} = {a^b, 2'b00}; //xor

            3'b101: {result, carry, overflow} = {a[6:0], 1'b0, a[7], 1'b0}; //left shift a by 1
            3'b110: {result, carry, overflow} = {1'b0, a[7:1], a[0], 1'b0}; //right shift a by 1
           
           default: {result, carry, overflow} = 10'b0000000000;
        endcase
    end

     assign zero = (result == 8'b00000000); 
     assign negative = result[7];
    //my understanding is that zero is to check stuff like a==b easily based on what was said on the group
endmodule


module flags_reg(input clk, we, zero, negative, carry, overflow, output reg zf, nf, cf, of);
    always @(posedge clk) begin
        if(we) {zf, nf, cf, of} <= {zero, negative, carry, overflow};
    end
endmodule
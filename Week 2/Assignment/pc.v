module pc(input clk, rst, inc, load, input [5:0] load_val, output reg [5:0] pc_out);

    initial pc_out = 6'b0;

    always @(posedge clk) begin
        if(rst) pc_out <= 6'b0; //reset
        else if(load) pc_out <= load_val; //load value from input
        else if(inc) pc_out = pc_out + 6'b000001; //increment
    end

endmodule

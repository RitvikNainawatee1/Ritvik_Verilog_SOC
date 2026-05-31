module mux2 #(parameter WIDTH = 8) (input [WIDTH-1:0] a, b, input sel, output [WIDTH-1:0] y);
	assign y = sel ? b:a;
endmodule

module mux4 #(parameter WIDTH = 8) (input [WIDTH-1:0] d0, d1, d2, d3, input [1:0] sel, output [WIDTH-1:0] y);
	assign y = sel[0] ? (sel[1]? d3 : d1) : (sel[1]? d2 : d0);
endmodule

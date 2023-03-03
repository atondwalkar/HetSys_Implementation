module ast_decoder_sv (
	d,
	q);
	
	parameter SIZE = 8;
	
	input logic [$clog2(SIZE)-1:0] d;
	output logic [SIZE-1:0] q;
	
	assign q = (1'b1 << d);
	
endmodule
		
module ast_tensor_system_sv (
	clk, 
	reset,
	depth,
	width,
	address_in,
	data_in,
	wen);
	
	parameter DATAWIDTH = 14;
	parameter SIZE = 1024;
	
	input logic clk, reset;
	input logic [$clog2(SIZE)-1:0] depth;
	input logic [$clog2(SIZE)-1:0] width;
	
	logic depth_counter;
	
	always_ff @ (posedge clk)
	begin
		if(reset)
			depth <= 0;
		else
			depth <= wen ? (depth + 1) : depth;
	end
	
	
	

	
	genvar i;
   generate //generate FIFO set A
		for (i=0; i<SIZE; i++) 
		begin : block
			ast_fifo_v fifo (
				.clock(clk),
				.data(data_in),
				rdreq,
				.sclr(reset),
				wrreq,
				q);
    end 
    endgenerate
	
	

systolic_array_sv #(.DATAWIDTH(DATAWIDTH), .SIZE(SIZE)) array (
    a_in,
    b_in,
    mult_en,
    acc_en,
    load_en,
    clk,
    reset,
    d_out
    );

endmodule


//Module performs A*B = X matrix multiplication

module ast_tensor_system_sv (
	clk, 
	reset,
	depth,	//column depth into FIFOs
	width,	//row width of FIFOs
	data_in,
	wen,		//write enable to push fifo
	set,	 	//set == 0 is fifo set A, otherwise B
	relu,		//enable ReLU
	busy,
	data_out,
	ren,
	start,
	done
	); 	
	
	parameter DATAWIDTH = 14;
	parameter SIZE = 4;
	
	input logic clk, reset, wen, set, ren, start, relu;
	input logic [$clog2(SIZE):0] depth, width;
	input logic [DATAWIDTH-1:0] data_in;
	output logic [DATAWIDTH-1:0] data_out;
	output logic busy, done;
	
	logic [$clog2(SIZE)-1:0] depth_counter, width_counter; //used for loading FIFOs with data
	logic [SIZE-1:0] decode_out, decode_out_B; //FIFO push select
		
	logic [$clog2(SIZE):0] result_depth_counter, result_width_counter; //used for loading FIFOs with data
	logic [SIZE-1:0] result_decode_out; //FIFO push select
	
	logic [$clog2(SIZE):0] depth_A, depth_B, width_A, width_B; //info for fetching output 1x7 * 7x3 = 1x3
	// depth - column size
	// width - row size
	
	logic [SIZE-1:0][DATAWIDTH-1:0] a_toarray, a_mux; 	
	logic [SIZE-1:0][DATAWIDTH-1:0] b_toarray, b_mux;
	logic [SIZE-1:0][SIZE-1:0][DATAWIDTH-1:0] d_fromarray, d_activation;
	
	logic finished_multiplicaiton, next_element; //from CU
	logic [SIZE-1:0] fifo_select_A, fifo_select_B; //FIFO pop from CU
	
	logic [$clog2(SIZE)+1:0] mac_cycles;
	
	
				
	//-------------------------------------------------------------------------------
	// Storing Matrix Dimensions
	
	always_ff @ (posedge clk)
	begin
		if(reset)
			depth_A <= 0;
		else
			depth_A <= (~set & wen) ? depth : depth_A;
	end
	
	always_ff @ (posedge clk)
	begin
		if(reset)
			width_A <= 0;
		else
			width_A <= (~set & wen) ? width : width_A;
	end
	
	always_ff @ (posedge clk)
	begin
		if(reset)
			depth_B <= 0;
		else
			depth_B <= (set & wen) ? depth : depth_B;
	end
	
		
	always_ff @ (posedge clk)
	begin
		if(reset)
			width_B <= 0;
		else
			width_B <= (set & wen) ? width : width_B;
	end
	
	
	//-------------------------------------------------------------------------------

	
	
	
	//-------------------------------------------------------------------------------
	// FIFO push control
	
	always_ff @ (posedge clk) //pushing into FIFO
	begin
		if(reset || (depth_counter == depth-1))
			depth_counter <= 0;
		else
			depth_counter <= wen ? (depth_counter + 1) : depth_counter;
	end
	
	always_ff @ (posedge clk) //going to next FIFO
	begin
		if(reset || ((width_counter == width-1) & (depth_counter == depth-1)))
			width_counter <= 0;
		else
			width_counter <= (wen & depth_counter == depth-1) ? (width_counter + 1) : width_counter;
	end
	
	
	ast_decoder_sv #(.SIZE(SIZE)) decoder (
		.d(width_counter),
		.q(decode_out)
	);

	ast_decoder_sv #(.SIZE(SIZE)) decoder_B (
		.d(depth_counter),
		.q(decode_out_B)
	);
	
	//-------------------------------------------------------------------------------


		
			
	//-------------------------------------------------------------------------------
	// FIFO set Matrix A and B generations
	
	genvar i;
   generate //generate FIFO set A
		for (i=0; i<SIZE; i++) 
		begin : block_A
			/*ast_fifo #(.DEPTH(SIZE), .DATAWIDTH(DATAWIDTH)) fifo_A (
				.clk(clk),
				.rst(reset),
				.pop(fifo_select_A[i] & next_element),
				.push(decode_out[i] & wen & ~set),
				.data_in(data_in),
				.data_out(a_toarray[i])
			);*/
			ast_ldfifo #(.DEPTH(SIZE), .DATAWIDTH(DATAWIDTH)) fifo_A (
				.clk(clk),
				.rst(reset),
				.pop(fifo_select_A[i] & next_element),
				.push(decode_out[i] & wen & ~set),
				.parallel_load(1'b0),
				.data_in(data_in),
				.data_out(a_toarray[i])
			);
   end 
   endgenerate

	
	genvar j;
   generate //generate FIFO set B
		for (j=0; j<SIZE; j++) 
		begin : block_B
			/*ast_fifo #(.DEPTH(SIZE), .DATAWIDTH(DATAWIDTH)) fifo_B (
				.clk(clk),
				.rst(reset),
				.pop(fifo_select_B[j] & next_element),
				.push(decode_out_B[j] & wen & set),
				.data_in(data_in),
				.data_out(b_toarray[j])
			);*/
			ast_ldfifo #(.DEPTH(SIZE), .DATAWIDTH(DATAWIDTH)) fifo_B (
				.clk(clk),
				.rst(reset),
				.pop(fifo_select_B[j] & next_element),
				.push(decode_out_B[j] & wen & set),
				.parallel_load(1'b0),
				.data_in(data_in),
				.data_out(b_toarray[j])
			);
   end 
   endgenerate
	
	integer mux_index;
	always_comb
	begin
		for (mux_index=0; mux_index<SIZE; mux_index++) 
		begin : mux_to_array
			a_mux[mux_index] = fifo_select_A[mux_index] ? a_toarray[mux_index] : 0;
			b_mux[mux_index] = fifo_select_B[mux_index] ? b_toarray[mux_index] : 0;
		end
	end

	//-------------------------------------------------------------------------------
	
	
	
	//-------------------------------------------------------------------------------
	// Systolic Array DP and CU
	
	logic load_en, mult_en, acc_en;
	
	ast_systolic_array_sv #(.DATAWIDTH(DATAWIDTH), .SIZE(SIZE)) array (
		 .a_in(a_mux),
		 .b_in(b_mux),
		 .mult_en(mult_en),
		 .acc_en(acc_en),
		 .load_en(load_en),
		 .clk(clk),
		 .reset(reset),
		 .d_out(d_fromarray)
	);
	
	assign mac_cycles = (depth_A + width_A + depth_B) - 1; //QxR * RxK -> cycles = R+Q+K-1
	
	ast_systolic_array_control_sv #(.SIZE(SIZE)) array_control (
        .clk(clk),
        .reset(reset),
        .cycles_in(mac_cycles), 
		  .width_A(width_A),
		  .width_B(width_B),
		  .load_en(load_en),
        .mult_en(mult_en),
        .acc_en(acc_en),
        .done(finished_multiplicaiton),
        .start(start),
        .memsel_A(fifo_select_A),
		  .memsel_B(fifo_select_B),
        .next(next_element),
		  .busy(busy)
    );
	 
	 assign done = finished_multiplicaiton;
	 
	//-------------------------------------------------------------------------------
	 
	 
	 
	//-------------------------------------------------------------------------------
	// Activation Function ReLU into Result FIFO
	 
	logic [SIZE-1:0][DATAWIDTH-1:0] data_out_mux; 
	integer act_r, act_c;
	
	always_comb
	begin
		for(act_r=0; act_r<SIZE; act_r++)
		begin
			for(act_c=0; act_c<SIZE; act_c++)
			begin
				d_activation[act_r][act_c] = (relu == 1) ? ((d_fromarray[act_r][act_c] > 0) ? d_fromarray[act_r][act_c] : 0) : d_fromarray[act_r][act_c];
			end
		end
	end

	genvar k;
   generate //generate FIFO set X
		for (k=0; k<SIZE; k++) 
		begin : block_X
			if(k != 0)
			ast_ldfifo #(.DEPTH(SIZE), .DATAWIDTH(DATAWIDTH)) fifo_X (
				.clk(clk),
				.rst(reset),
				.pop((((result_depth_counter == depth_B-1) & result_decode_out[k-1]) || result_decode_out[k]) & ren),
				.parallel_load(finished_multiplicaiton),
				.array_in(d_activation[k]),
				.data_out(data_out_mux[k])
			);
			else
			ast_ldfifo #(.DEPTH(SIZE), .DATAWIDTH(DATAWIDTH)) fifo_X (
				.clk(clk),
				.rst(reset),
				.pop(result_decode_out[k] & ren),
				.parallel_load(finished_multiplicaiton),
				.array_in(d_activation[k]),
				.data_out(data_out_mux[k])
			);
   end 
   endgenerate
	
	assign data_out = data_out_mux[result_width_counter];
	
	//-------------------------------------------------------------------------------
	
	
	
	//-------------------------------------------------------------------------------
	// Result FIFO pop control
	
	always_ff @ (posedge clk) //pushing into FIFO
	begin
		if(reset)
			result_depth_counter <= {($clog2(SIZE)+1){1'b1}};
		else if(result_depth_counter == depth_B-1)
			result_depth_counter <= 0;
		else
			result_depth_counter <= ren ? (result_depth_counter + 1) : result_depth_counter;
	end
	
	always_ff @ (posedge clk) //going to next FIFO
	begin
		if(reset || ((result_width_counter == width_A-1) & (result_depth_counter == depth_B-1)))
			result_width_counter <= 0;
		else
			result_width_counter <= (ren & result_depth_counter == depth_B-1) ? (result_width_counter + 1) : result_width_counter;
	end
	
	
	ast_decoder_sv #(.SIZE(SIZE)) result_decoder (
		.d(result_width_counter),
		.q(result_decode_out)
	);

	//-------------------------------------------------------------------------------
	
	
		 
endmodule

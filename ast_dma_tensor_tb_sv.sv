`timescale 1ns / 10ps

module ast_dma_tensor_tb_sv;

   parameter SIZE = 4;
	parameter DATAWIDTH = 14;

   logic clk, reset;
	logic write_dma, rW_dma_out;
	logic [2:0] dma_select;
	logic [DATAWIDTH-1:0] dma_address_out;
	logic	[DATAWIDTH-1:0] dma_in;
	logic [DATAWIDTH-1:0] dma_depth, dma_width;
	logic dma_set, tensor_ren, tensor_wen, done;
	
	logic [DATAWIDTH-1:0] ram_out;
	
	
	logic [$clog2(SIZE):0] depth, width;
	logic [$clog2(SIZE)-1:0] cycles_in;
	logic [DATAWIDTH-1:0] data_in, data_out;
	logic wen, ren, set, relu, start, busy, dma_fin_transfer;
	
   logic [SIZE-1:0][SIZE-1:0][DATAWIDTH-1:0] matrix_a = '{'{5, 2, 6, 1},'{0, 6, 2, 0},'{3, 8, 1, 4},'{1, 8, 5, 6}};
   logic [SIZE-1:0][SIZE-1:0][DATAWIDTH-1:0] matrix_b = '{'{7, 5, 8, 0},'{1, 8, 2, 6},'{9, 4, 3, 8},'{5, 3, 7, 9}};

	
	ast_dma_sv #(.DATAWIDTH(DATAWIDTH)) dma (
		.clk(clk),
		.rst(reset),
		.write(write_dma),
		.data_in(dma_in),
		.select(dma_select),
		.address_out(dma_address_out),
		.rW_out(rW_dma_out),
		.depth_out(dma_depth),
		.width_out(dma_width),
		.set(dma_set),
		.tensor_wen(tensor_wen),
		.tensor_ren(tensor_ren),
		.busy(),
		.finished_transfer(dma_fin_transfer)
	);
	
	ast_tensor_system_sv #(.SIZE(SIZE), .DATAWIDTH(DATAWIDTH)) tensor_subsystem (
		.clk(clk), 
		.reset(reset),
		.depth(dma_depth),
		.width(dma_width),
		.data_in(ram_out),
		.wen(tensor_wen),
		.ren(tensor_ren),
		.set(dma_set),
		.relu(relu),
		.start(start),
		.busy(busy),
		.data_out(data_out),
		.done(done)
	);
	
	astRISC621_ram	#(.initfile("nndata.mif")) ram (
		.address(dma_address_out),
		.clock(clk),
		.data(data_out),
		.wren(rW_dma_out),
		.q(ram_out)
	);

	
	
	
   integer i, j, k;


	initial begin 
		clk = 0;
		forever begin
		#10 clk = ~clk;
	end end 	
	 
	initial begin
		reset = 1;
		write_dma = 0;
		dma_select = 0;
		dma_in = 0;
		#40;
		reset = 0;
		dma_in = 4;
		write_dma = 1;
		dma_select = 0;
		#20;
		write_dma = 1;
		dma_select = 1;
		#20;
		dma_in = 0;
		write_dma = 1;
		dma_select = 2;
		#20;
		dma_in = 0;
		write_dma = 1;
		dma_select = 4;
		#20;
		dma_in = 1;
		write_dma = 1;
		dma_select = 3;
		#20;
		write_dma = 0;
		#20;
		wait(dma_fin_transfer == 1);
		#20;
		dma_in = 14'h10;
		write_dma = 1;
		dma_select = 4;
		#20;
		dma_in = 1;
		write_dma = 1;
		dma_select = 2;
		#20;
		dma_in = 1;
		write_dma = 1;
		dma_select = 3;
		#20;
		write_dma = 0;
		#20;
		wait(dma_fin_transfer == 1);
		#20;
		start = 1;
		#20;
		start = 0;
		#20;
		wait(done == 1)
		#20;
		dma_in = 14'h20;
		write_dma = 1;
		dma_select = 4;
		#20;
		dma_in = 2;
		write_dma = 1;
		dma_select = 2;
		#20;
		dma_in = 1;
		write_dma = 1;
		dma_select = 3;
		#20;
		write_dma = 0;
		#20;
		wait(dma_fin_transfer == 1);
		#20
		$stop;
		
	end
	
	initial
    #10000 $stop;

endmodule
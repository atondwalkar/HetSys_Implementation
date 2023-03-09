`timescale 1ns / 10ps

module ast_super_system_sv(
	input clk,
	input reset,
	input	logic [4:0] SW_in,
	output [7:0] Display_out,
	output [95:0] ICis
	);

   parameter SIZE = 4;
	parameter DATAWIDTH = 14;

	logic write_dma, rW_dma_out;
	logic [2:0] dma_select;
	logic [DATAWIDTH-1:0]dma_address_out;
	logic	[DATAWIDTH-1:0] dma_in;
	logic [DATAWIDTH-1:0] dma_depth, dma_width;
	logic tensor_ren, tensor_wen, start_mxu, pause_gpp;
	logic [1:0] dma_set;
	
	logic [DATAWIDTH-1:0] ram_out;
	
	logic [$clog2(SIZE):0] depth, width;
	logic [$clog2(SIZE)-1:0] cycles_in;
	logic [DATAWIDTH-1:0] data_in, data_out;
	logic wen, ren, set, relu, start, mxu_busy, dma_busy;
	
	logic [DATAWIDTH-1:0] ram_addr, ram_data; 
	logic ram_clk, ram_wren;
	
	logic [DATAWIDTH-1:0] cache_ram_addr; 
	logic cache_ram_clk, cache_ram_wr;
	logic [DATAWIDTH-1:0] cache_ramdatain;
	
	logic cache_done, Cache_WR;
	logic [DATAWIDTH-1:0] Cache_Memaddr, Cache_datain, Cache_dataout;
	
   //logic [SIZE-1:0][SIZE-1:0][DATAWIDTH-1:0] matrix_a = '{'{5, 2, 6, 1},'{0, 6, 2, 0},'{3, 8, 1, 4},'{1, 8, 5, 6}};
   //logic [SIZE-1:0][SIZE-1:0][DATAWIDTH-1:0] matrix_b = '{'{7, 5, 8, 0},'{1, 8, 2, 6},'{9, 4, 3, 8},'{5, 3, 7, 9}};

	
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
		.busy(dma_busy)
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
		.start(start_mxu),
		.busy(mxu_busy),
		.data_out(data_out)
	);
	
	
	assign ram_addr = dma_busy ? dma_address_out : cache_ram_addr;
	assign ram_clk = dma_busy ? clk : cache_ram_clk;
	assign ram_wren = dma_busy ? rW_dma_out : cache_ram_wr;
	assign ram_data = dma_busy ? data_out : cache_ramdatain;
	
	astRISC621_ram	#(.initfile("nndata.mif")) ram (
		.address(ram_addr),
		.clock(ram_clk),
		.data(ram_data),
		.wren(ram_wren),
		.q(ram_out)
	);
	
	
	
	assign pause_gpp = dma_busy | mxu_busy;
	
	ast_621RISC_SIMD_v gpp (
		.Resetn_pin(~reset), 
		.Clock_pin(clk),  
		.ICis(ICis),
		.DMA_data_out(dma_in), 
		.DMA_select_out(dma_select), 
		.DMA_write_out(write_dma), 
		.Start_MXU_out(start_mxu),
		.Pause_in(pause_gpp),
		.SW_pin(SW_in), 
		.Display_pin(Display_out),
		.Cache_Memaddr_out(Cache_Memaddr), 
		.Cache_WR_out(Cache_WR), 
		.Cache_done_in(cache_done), 
		.Cache_datain_out(Cache_datain), 
		.Cache_dataout_in(Cache_dataout)
	);

	
	ast_data_cache_2w_v dcache (
		.Resetn(~reset),
		.MEM_address(Cache_Memaddr),
		.MEM_in(Cache_datain),		
		.WR(Cache_WR), 
		.Clock(~clk), 
		.MEM_out(Cache_dataout), 
		.Done(cache_done), 
		.RAM_addr_out(cache_ram_addr),
		.RAM_clk_out(cache_ram_clk), 
		.RAM_inputdata_out(cache_ramdatain), 
		.RAM_wen_out(cache_ram_wr), 
		.RAM_outputdata_in(ram_out),
		.snoop_wen(rW_dma_out),
		.snoop_addr(dma_address_out),
		.snoop_data(data_out)
	);

	
	
	

endmodule


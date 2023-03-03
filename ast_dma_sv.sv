module ast_dma_sv #(parameter DATAWIDTH = 8) (
  input 	clk,
  input 	rst,
  input	write,
  input	[DATAWIDTH-1:0] data_in,
  input	[2:0] select,
  output logic [DATAWIDTH-1:0] address_out,
  output logic rW_out,
  output logic [DATAWIDTH-1:0] depth_out,
  output logic [DATAWIDTH-1:0] width_out,
  output logic tensor_ren,
  output logic tensor_wen,
  output logic [1:0] set,
  output logic busy,
  output logic finished_transfer
  );
  
  
  logic [5:0][DATAWIDTH-1:0] mem;
  /*	0 - Depth
  *	1 - Width
  *	2 - A(0), B(1), X(2, pop)
  *	3 - start transfer
  *	4 - Current/Source Addr
  *	5 - final Addr
  */
  
  //logic	[DATAWIDTH-1:0] final_address;
	logic		[1:0] fifo_delay;
  
	integer index;
	always @ (posedge clk)
	begin
		if(rst)
		begin
			finished_transfer <= 0;
			busy <= 0;
			rW_out<= 0;
			tensor_wen <= 0;
			tensor_ren <= 0;
			for(index=0; index<=5; index++)
				mem[index] <= 0;
			fifo_delay <= 0;
		end
		else
		begin
			if(write)
			begin
				mem[select] <=  write ? data_in : mem[select];
				finished_transfer <= 0;
				busy <= 0;
				tensor_ren <= 0;
				tensor_wen <= 0;
				fifo_delay <= 0;
				if(select == 3)
					mem[5] <= mem[4] + mem[1]*mem[0];
			end
			/*else if((mem[4] == mem[5] - 1) && mem[3][0] && mem[2] == 2)
			begin
				finished_transfer <= 1;
				fifo_delay <= 0;
				busy <= 0;
				mem[3] <= 0;
				rW_out <= 0;
				tensor_ren <= 0;
				tensor_wen <= 0;
				mem[5] <= 0;
			end*/		
			else if((mem[4] == mem[5]) && mem[3][0])
			begin
				finished_transfer <= 1;
				fifo_delay <= 0;
				busy <= 0;
				mem[3] <= 0;
				rW_out <= 0;
				tensor_ren <= 0;
				tensor_wen <= 0;
				mem[5] <= 0;
			end
			else if((fifo_delay != 2'b10) && mem[3][0])
			begin
				fifo_delay <= fifo_delay + 1;
				if(mem[2] == 2) begin tensor_ren <= 1; end
				//rW_out <= 0;
				busy <= 1;
				if(fifo_delay == 2'b01 && mem[2] == 2) begin rW_out <= 1; end
				else rW_out <= 0;
				//mem[4] = mem[4] - 1;
			end
			/*else if(mem[3][0] && (mem[2] == 2) && (mem[4] == mem[5]-1))
			begin
				finished_transfer <= 0;
				mem[4] = mem[4] + 1;
				rW_out <= 1;
				tensor_ren <= 0;
				busy <= 1;
			end*/
			/*else if(mem[3][0] && mem[2] == 2 && mem[4] == mem[5] - 1)
			begin
				rW_out <= 0;
				mem[4] = mem[4] + 1;
			end	*/
			else if(mem[3][0])
			begin
				finished_transfer <= 0;
				mem[4] = mem[4] + 1;
				busy <= 1;
				rW_out <= (mem[2] == 2) ? 1 : 0;
				tensor_ren <= (mem[2] == 2) ? 1 : 0;
				tensor_wen <= (mem[2] == 2) ? 0 : 1;
			end
			else
			begin
				finished_transfer <= 0;
				busy <= 0;
				tensor_wen <= 0;
				tensor_ren <= 0;
				fifo_delay <= 0;
			end
		end
	end
	/*
	always @ (posedge mem[4][0]  posedge clk)
	begin
			final_address <= mem[2] + mem[1]*mem[0];
	end
	*/
	
	assign address_out = mem[4];
	assign depth_out = mem[0];
	assign width_out = mem[1];
	assign set = mem[2][1:0];
	//assign busy = mem[3][0];
  

endmodule

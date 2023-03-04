module ast_ldfifo #(parameter DEPTH = 8, parameter DATAWIDTH = 8) (
  input clk,
  input rst,
  input rst_ptr,
  input push,
  input pop,
  input parallel_load,
  input [DEPTH-1:0][DATAWIDTH-1:0] array_in,
  input [DATAWIDTH-1:0] data_in,
  output reg [DATAWIDTH-1:0] data_out,
  output reg empty,
  output reg full
);
  
  reg [DEPTH-1:0][DATAWIDTH-1:0] mem ;
  reg [$clog2(DEPTH)-1:0] write_ptr, read_ptr;

  integer i;
  
  always @(posedge clk) begin
    if (rst) 
	 begin
      write_ptr <= 0;
      read_ptr <= 0;
      empty <= 1;
      full <= 0;
		data_out <= 0;
		for(i=0; i<DEPTH; i++) mem[i] <= 0;
    end
    else if(rst_ptr)
	 begin
		write_ptr <= 0;
		read_ptr <= 0;
		empty <= 1;
      full <= 0;
		data_out <= 0;
	 end
	 else 
	 begin
      if(parallel_load)
		begin
			for(i=0; i<DEPTH; i++)
			begin
				mem[i] <= array_in[i];
				write_ptr <= DEPTH-1;
				read_ptr <= 0;
				full <= 1;
				empty <= 0;
			end
		end
		else
		begin	
			if (push & !full) begin
			  mem[write_ptr] <= data_in;
			  write_ptr <= write_ptr + 1;
			  if (write_ptr == DEPTH) full <= 1;
			  if (write_ptr == read_ptr) empty <= 0;
			end
			if (pop & !empty) begin
			  data_out <= mem[read_ptr];
			  read_ptr <= read_ptr + 1;
			  if (read_ptr == DEPTH) empty <= 1;
			  if (write_ptr == read_ptr) full <= 0;
			end
		end
    end
  end

endmodule
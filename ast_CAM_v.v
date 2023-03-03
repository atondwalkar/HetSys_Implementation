module ast_CAM_v (we_n, rd_n, din, argin, addrs, dout, mbits);

//----------------------------------------------------------------------------
//-- Declare input and output port types
//----------------------------------------------------------------------------
	input	we_n, rd_n; 		//write and read enables
	input	[7:0]	din; //data input and argument input busses
	input [7:0] argin;
	input	[1:0]	addrs;		//address input bus; points to 8 locations
	output reg	[7:0]	dout;
	output reg [3:0] mbits; //data output bus and mbits = match bits
//----------------------------------------------------------------------------
//-- Declare internal memory array
//----------------------------------------------------------------------------
	reg	[7:0] cam_mem [3:0]; //4x2 CAM array withn 8 bit tag
	integer	k, i, int_addrs;
//----------------------------------------------------------------------------
//-- The WRITE procedural block.
//-- This enables a new tag value to be written at a specific location, 
//--    using a WE, data input and address input busses as with any
//--    other memory.
//-- In the context of a cache, this happens when a new block is 
//--    uploaded in the cache.
//----------------------------------------------------------------------------

initial begin for (i=0; i<4; i=i+1) cam_mem[i] = {8{1'b1}}; 
		mbits = {4{1'b0}};	end

	always @ (we_n, din, addrs)
		begin
			int_addrs = addrs;
			if (we_n == 1)
				begin
					cam_mem[int_addrs] = din;
				end
		end
//----------------------------------------------------------------------------
//-- The READ procedural block.
//-- This allows a value at a specific location to be read out, 
//--    using a RD, data output and address input busses as with any
//--    other memory.
//-- In the context of a cache, this is not necessary. This functionality 
//--    is provided here for reference and debugging purposes.
//----------------------------------------------------------------------------
	always @ (rd_n, addrs, cam_mem)
		begin
			int_addrs = addrs;
			if (rd_n == 1)
				begin
					dout = cam_mem[int_addrs];
				end
			else
				begin
					dout = 8'bzzzzzzzz;
				end
		end
//----------------------------------------------------------------------------
//-- The MATCH procedural block.
//-- This implements the actual CAM function.
//-- An mbit is 1 if the argument value is equal to the content of the 
//--    memory location associated with it.
//----------------------------------------------------------------------------
	always @ (argin, cam_mem)
		begin
			mbits = 4'b0000;
			for (k=0; k <= 3; k=k+1)
				begin
					if (argin == cam_mem[k])
						begin
							mbits[k] = 1;
						end
				end
		end
endmodule

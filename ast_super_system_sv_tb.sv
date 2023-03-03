// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on

module ast_super_system_sv_tb;
	reg	Resetn_tb, Clock_tb;
	reg	[4:0] SW_in_tb;
	wire [7:0] Display_out_tb;
	wire [95:0] ICis_tb;
	integer i;

ast_super_system_sv	dut	(
	.clk(Clock_tb), 
	.reset(Resetn_tb), 
	.SW_in(SW_in_tb), 
	.Display_out(Display_out_tb), 
	.ICis(ICis_tb)
	);
	

initial	begin	
//----------------------------------------------------------------------------
//	Resetn_tb, Clock_tb, SW_in_tb, Display_out_tb
//----------------------------------------------------------------------------
//-- Test Vector 1 (40ns): Reset
//----------------------------------------------------------------------------
	for (i=0; i<10; i=i+1) apply_test_vector(1, 0, 5'b00000);
//----------------------------------------------------------------------------
//-- All other test vectors
//----------------------------------------------------------------------------
	for (i=0; i<10; i=i+1) apply_test_vector(0, 0, 5'b00000);
	for (i=10; i<500; i=i+1) apply_test_vector(0, 0, 5'b01111);
end

task apply_test_vector;
	input	Resetn_int, Clock_int;
	input	[4:0] SW_in_int;
	
	begin
		Resetn_tb = Resetn_int; Clock_tb = Clock_int; SW_in_tb = SW_in_int;
		#20000; Clock_tb = 1; #20000;  Clock_tb = 0;
	end
endtask
endmodule

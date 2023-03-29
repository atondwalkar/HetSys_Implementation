	`timescale 1ns / 1ps

module ast_systolic_array_control_sv (
 clk,
 reset,
 cycles_in,
 depth_A,
 width_B,
 start,
 load_en,
 mult_en,
 acc_en,
 memsel_A,
 memsel_B,
 next,
 done,
 compress,
 busy,
 comp_add,
 comp_en,
 comp_ld
 );
	 
	 parameter SIZE = 16;
	 
	 input logic clk, reset, start, compress;
	 input logic [$clog2(SIZE)+1:0] cycles_in;
	 input logic [$clog2(SIZE):0] depth_A, width_B; //row dimensions for mem select
	 output logic load_en, mult_en, acc_en;
	 output logic [SIZE-1:0] memsel_A, memsel_B;
	 output logic done, next, busy, comp_add, comp_en, comp_ld;
	 
	 logic [3:0] state;
	 logic [1:0] mac_cycles;
	 logic [$clog2(SIZE)+1:0] cycles;
	 //logic [$clog2(SIZE):0] cycles_max;
	 
	 initial
	 begin
		  state <= 0;
	 end
	 
	 always @ (posedge clk)
	 begin
		  if(reset)
		  begin
				state <= 0;
				load_en <= 0;
				mult_en <= 0;
				acc_en <= 0;
				memsel_A <= 0;
				memsel_B <= 0;
				cycles <= 0;
				mac_cycles <= 0;
				//cycles_max <= 0;
				done <= 0;
				next <= 0;
				busy <= 0;
				comp_add <= 0;
				comp_en <= 0;
				comp_ld <= 0;
		  end
		  if(state == 0)
		  begin
				if(compress)
				begin
					state <= 5;
					busy <= 1;
				end
				else if(start)
				begin
					 state <= 1;
					 //cycles_max <= (cycles_in << 1) - 1; //2n-1
					 busy <= 1;
				end
				else
				begin
					 state <= 0;
					 load_en <= 0;
					 mult_en <= 0;
					 acc_en <= 0;
					 memsel_A <= 0;
					 memsel_B <= 0;
					 cycles <= 0;
					 mac_cycles <= 0;
					 //cycles_max <= 0;
					 done <= 0;
					 next <= 0;
					 busy <= 0;
					 comp_add <= 0;
					 comp_en <= 0;
					 comp_ld <= 0;
				end
		  end
		  if(state == 1)
		  begin
				busy <= 1;
				//if(cycles != cycles_max + 1) 
				if(cycles != cycles_in + 1) //how many elements to multiply in array
				begin
					 case (mac_cycles) //mac unit has 3 steps
						  0   : 
								begin //load popped data/run accummulation
									mac_cycles <= 1;
									load_en <= 1;
									mult_en <= 0;
									acc_en <= 1;
									next <= 0;
								end
						  1   :
								begin //run multiplication
									mac_cycles <= 0;
									load_en <= 0;
									mult_en <= 1;
									acc_en <= 0;
									next <= 1;
									cycles <= cycles + 1;
									if(cycles < depth_A)
										 memsel_A <= {memsel_A[SIZE-2:0], 1'b1}; 
									else
										 memsel_A <= {memsel_A[SIZE-2:0], 1'b0};
									if(cycles < width_B)
										 memsel_B <= {memsel_A[SIZE-2:0], 1'b1}; 
									else
										 memsel_B <= {memsel_A[SIZE-2:0], 1'b0};
								end
						  default :
								begin
									mac_cycles <= 0;
									load_en <= 0;
									mult_en <= 0;
									acc_en <= 0;
									next <= 0;
								end
					 endcase
				end
				else
				begin
					 state <= 2;
					 load_en <= 0;
					 mult_en <= 0;
					 acc_en <= 0;
					 next <= 0;
					 busy <= 1;
				end
		  end
		  if(state == 2)
		  begin
				done <= 1;
				state <= 3;
				busy <= 0;
		  end
		  if(state == 3)
		  begin
				done <= 0;
				busy <= 0;
				state <= 0;
		  end
		  if(state == 4)
		  begin
				//comp_en <= 1;
				comp_ld <= 1;
				comp_en <= 0;
				comp_add <= 0;
				state <= 6;
		  end
		  if(state == 5)
		  begin
				cycles <= cycles + 1;
				comp_add <= 1;
				comp_en <= 1;
				if(cycles == depth_A)
					state <= 4;
		  end
		  if(state == 6)
		  begin
				cycles <= 0;
				state <= 0;
				busy <= 0;
				comp_ld <= 1;
				done <= 1;
		  end
	 
	 end
	 
	 
endmodule

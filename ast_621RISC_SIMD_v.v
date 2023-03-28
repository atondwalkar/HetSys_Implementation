	// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
//----------------------------------------------------------------------------
// dxpRISC521pipe_v	Harvard	Memory Mapped I/O-Ps - top 16 locations; however,
// considering the DE0-Nano board only one input {PB1, Switches} and 
// one output {8xLEDs} peripherals are implemented.
// (c) Dorin Patru 2022
//----------------------------------------------------------------------------

module ast_621RISC_SIMD_v (Resetn_pin, Clock_pin, SW_pin, Display_pin, ICis, DMA_data_out, DMA_select_out, DMA_write_out, Pause_in, Start_MXU_out, Cache_Memaddr_out, Cache_WR_out, Cache_done_in, Cache_datain_out, Cache_dataout_in);

	input	Resetn_pin, Clock_pin, Pause_in;
	input	[4:0] SW_pin;			// Four switches and one push-button
	output [7:0] Display_pin;	// 8 LEDs
	output [95:0] ICis; // For simulation ONLY; should be commented out for 
	output reg [13:0] DMA_data_out;
	output reg [2:0] DMA_select_out;
	output reg DMA_write_out, Start_MXU_out;
	output [13:0] Cache_Memaddr_out;
	output Cache_WR_out;
	input Cache_done_in;
	output [13:0] Cache_datain_out;
	input [13:0] Cache_dataout_in;
	
								//board emulation!
//----------------------------------------------------------------------------
//-- Declare instruction cycle parameters
//----------------------------------------------------------------------------
/*	parameter [3:0] 	LD_IC=4'b0000, 	ST_IC=4'b0001, 	//reg-mem data transfer instruction cycles
							CPY_IC=4'b0010, 	SWAP_IC=4'b0011, 	//reg-reg data transfer instruction cycles
							JMP_IC=4'b0100, 							//flow control instruction cycle
							ADD_IC=4'b0101, 	SUB_IC=4'b0110, 	//arithmetic manipulation instruction
							ADDC_IC=4'b0111, 	SUBC_IC =4'b1000, //cycles
							NOT_IC=4'b1001, 	AND_IC=4'b1010,  	//logic manipulation instruction 
							OR_IC=4'b1011,								//cycles
							SRA_IC=4'b1100, 	RRC_IC=4'b1101,	//shift/rotate instruction cycles 
							VADD_IC=4'b1110, 	VSUB_IC=4'b1111;	//SIMD (vector) instruction cycles 
																			//cycles - to be implemented later*/
	//parameter [1:0] MC0=2'b00, MC1=2'b01, MC2=2'b10, MC3=2'b11; //machine cycles
	parameter [5:0] 	LD_IC=6'b000000, 	ST_IC=6'b000001, 	//reg-mem data transfer instruction cycles
							CPY_IC=6'b000010, 	SWAP_IC=6'b000011, 	//reg-reg data transfer instruction cycles
							JMP_IC=6'b000100, 							//flow control instruction cycle
							ADD_IC=6'b000101, 	SUB_IC=6'b000110, 	//arithmetic manipulation instruction
							ADDC_IC=6'b000111, 	SUBC_IC =6'b001000, //cycles
							NOT_IC=6'b001001, 	AND_IC=6'b001010,  	//logic manipulation instruction 
							OR_IC=6'b001011,								//cycles
							SRA_IC=6'b001100, 	SRL_IC=6'b001101,	//shift/rotate instruction cycles 
							VADD_IC=6'b001110, 	VSUB_IC=6'b001111,	//SIMD (vector) instruction cycles 
							
							MUL_IC=6'b010000, DIV_IC=6'b010001,
							XOR_IC=6'b010010,	ROTL_IC=6'b010011,
							ROTR_IC=6'b010100,	RLZ_IC=6'b010101,
							RLN_IC=6'b010110,	RRC_IC=6'b010111,
							RRV_IC=6'b011000,
							
							CALL_IC=6'b011001, RET_IC=6'b011010,

							CFGDMA_IC = 6'b011011, SMXU_IC = 6'b011100,
							
							NOP_IC = 6'b111110;
																			
																			
	parameter [3:0] JU=4'b0000, JC1=4'b1000, JN1=4'b0100, JV1=4'b0010, //Jump condition(s) 
		JZ1=4'b0001, JC0=4'b0111, JN0=4'b1011, JV0=4'b1101, JZ0=4'b1110; //definition(s)
//----------------------------------------------------------------------------
//-- Declare internal signals
//----------------------------------------------------------------------------
	reg signed [13:0] R [63:0]; //Register File (RF) 64 16-bit registers
	reg	WR_DM, stall_mc0, stall_mc1, stall_mc2, stall_mc3;
	reg [13:0] PC, IR3, IR2, IR1, MAB, MAX, MAeff, DM_in;
	reg signed [13:0] TA, TB, TALUH, TALUL;
	reg [11:0] TSR, SR;
	reg [7:0] Display_pin;
	reg [14:0]	TALUout;
	reg [7:0] TALUV_H, TALUV_L;
	wire [13:0]	PM_out, DM_out;
	wire PM_done, DM_done;
	wire Clock_not;
	
	reg [13:0] T_DMA_data_out;
	
	integer Ri1, Rj1, Ri2, Rj2, Ri3, Rj3; // These are Ri and Rj field values
								// of the instructions currently in MC1, MC2, and MC3.
	integer k;
	
	
	//wire [5:0] IW; assign IW = IR3[13:8];
	reg	throwaway_bit;
	reg [13:0] SP;
	initial begin SP = 14'h3FF0; end
	reg DM_ctrl;
	wire [13:0] DM_addr;
	
	reg [13:0] DMA_depth, DMA_width;
	reg nop_status;
//----------------------------------------------------------------------------
// In this architecture we are using a combination of structural and 
// 	behavioral code.  Care has to be excercised because the values assigned
//		in the always block are visible outside of it only during the next clock 
//		cycle.  The CPU comprised of the DP and CU is modeled as a combination
// 	of CASE and IF statements (behavioral).  The memories are called within
// 	the structural part of the code.  We could model the memories as
//		arrays, but that would result in less than optimal memory 
//		implementations.  Also, later on we will want to add an hierarchcial 
//		memory subsystem.
//----------------------------------------------------------------------------
// Structural section of the code.  The order of the assignments doesn't 
// 	matter.  Concurrency!
//----------------------------------------------------------------------------
		assign	Clock_not = ~Clock_pin;
//----------------------------------------------------------------------------
// Instantiating only 1KWord memories to save resources;
// I could instantiate up to 64KWords.
// Both memories are clock synchronous i.e., the address and eventually input 
// data have to be first registered; to save a clock cycle we use the "other"
// edge/ event of the clock.
//----------------------------------------------------------------------------
		//dxpRISC521_rom1	my_rom	(PC[9:0], Clock_not, PM_out);
		//dxpRISC521_ram1	my_ram	(MAeff[9:0], Clock_not, DM_in, WR_DM, DM_out);
		
		//ast_rom	my_rom	(PC[9:0], Clock_not, PM_out);
		//assign DM_addr = ((IR2[13:8] == LD_IC) || (IR2[13:8] == ST_IC)) ? (DM_ctrl ? {4'h0, SP} : {4'h0, MAeff[9:0]}) : DM_addr;
		assign DM_addr = DM_ctrl ? {4'h0, SP} : MAeff;
		//ast_ram	my_ram	(DM_addr, Clock_not, DM_in, WR_DM, DM_out);
		
		//ast_cache_2w_v #(.initfile("blank.mif")) my_ram (.Clock(Clock_not), .Resetn(Resetn_pin), .MEM_address(DM_addr), .WR(WR_DM), .MEM_out(DM_out), .MEM_in(DM_in), .Done(DM_done));
		assign Cache_Memaddr_out = DM_addr;
		assign Cache_WR_out = WR_DM;
		assign Cache_datain_out = DM_in;
		assign DM_done = Cache_done_in;
		assign DM_out = Cache_dataout_in;
		
		
		ast_cache_2w_v #(.initfile("dma_test.mif")) my_rom (.Clock(Clock_not), .Resetn(Resetn_pin), .MEM_address(PC[13:0]), .WR(1'b0), .MEM_out(PM_out), .MEM_in(14'b0), .Done(PM_done));
		
//----------------------------------------------------------------------------
// The "dis-assembler" module; useful during verification thorugh simulation;
// Should be commented out when performing full compilation targeting the FPGA
//----------------------------------------------------------------------------
		ast_ir2assembly_v IWdecode (IR3, Resetn_pin, Clock_pin, ICis);
//----------------------------------------------------------------------------
//	Behavioral section of the code.  Assignments are evaluated in order, i.e.
// 	sequentially. New assigned values are visible outside the always block 
// 	only after it is exit.  Last assigned value will be the exit value.
//----------------------------------------------------------------------------
		always@(posedge Clock_pin)
//----------------------------------------------------------------------------
// The reset is active low and clock synchronous.  For verification/simulation
// 	purposes it is necessary in this case to initialize all values.
//----------------------------------------------------------------------------
	

				if (Resetn_pin == 0) begin	
					PC = 14'h0000; //Initialize the PC to point to the location of 
			//the FIRST instruction to be executed; location 0000 is arbitrary!
					for (k = 0; k < 64; k = k+1) begin R[k] = 0; end // Necessary for sim					
			// The initialization of the stall_mc signals is necessary for 
			// the correct startup of the pipeline.
						stall_mc0 = 0; stall_mc1 = 1; stall_mc2 = 1; stall_mc3 = 1;
			// All IRs are initialized to the "don't care OpCode value 0xffff
						IR1 = 14'h3fff; IR2 = 14'h3fff; IR3 = 14'h3fff;
					MAB = 14'h0000; MAX = 14'h0000; MAeff = 14'h0000; DM_in = 14'h0000;
					TA = 14'h0000; TB = 14'h0000; TALUH = 14'h0000; TALUL = 14'h0000;
					TSR = 12'b000; SR = 12'b000; TALUout = 15'h00000; WR_DM = 1'b0;
					Ri1 = 0; Rj1 = 0; Ri2 = 0; Rj2 = 0; Ri3 = 0; Rj3 = 0;
					DM_ctrl = 0;
					DMA_depth = 0; DMA_width = 0; DMA_write_out = 0; DMA_select_out = 0;
					nop_status = 0;
					Start_MXU_out = 0;
					end
				else	
				begin
				
	if(Pause_in)
	begin
		DMA_write_out = 0;
		Start_MXU_out = 0;
	end
	else if((PM_done && DM_done) && ~Pause_in)
	begin
				
				
				
//----------------------------------------------------------------------------
// MC3 is executed first because its assignments might be needed by the 
// 	instructions executing MC2 or MC1 to resolve data or control D/H.
// 	An instruction that has arrived in MC3 does not have any dependency.
//----------------------------------------------------------------------------
	if (stall_mc3 == 0) begin 
//----------------------------------------------------------------------------
		case (IR3[13:8])
			NOP_IC: begin
				nop_status = 0;
			end
			CFGDMA_IC: begin
				DMA_write_out = 0;
				//DMA_select_out = 3'b0;
			end
			SMXU_IC: begin
				Start_MXU_out = 0;
			end
			LD_IC: begin
//If MAeff points to the top location of the memory address space, read from
// the INPUT PERIPHERAL(PB1 & Switches) ...
				if (MAeff[13:4] == 10'h3FF) 
					R[IR3[3:0]] = {9'b000000000, SW_pin};												
// ... Else, read the Data Memory Output.
					else R[IR3[3:0]] = DM_out; end
//----------------------------------------------------------------------------
			ST_IC: begin
// If MAeff points to the top location of the memory address space, write to
// the OUTPUT PERIPHERAL(8xLEDs) i.e., the least significant 8-bits only.
				if (MAeff[13:4] == 10'h3FF) 
					Display_pin = R[IR3[3:0]][7:0]; end
//	... Else do nothing here, because the write to DM was initiated in MC2.
			CALL_IC: begin
				PC = MAeff;
				//DM_in = SR;
				DM_ctrl = 1'b0;
				WR_DM = 1'b0;
			end
			RET_IC: begin
				DM_ctrl = 1'b0;
			end
//----------------------------------------------------------------------------
			CPY_IC: begin R[IR3[7:4]] = TALUL; end
			SWAP_IC: begin R[IR3[7:4]] = TALUH; R[IR3[3:0]] = TALUL; end
//----------------------------------------------------------------------------
			JMP_IC: begin
				case (IR3[3:0])
					JC1: begin if (SR[11] == 1) PC = MAeff; else PC = PC; end
					JN1: begin if (SR[10] == 1) PC = MAeff; else PC = PC; end
					JV1: begin if (SR[9] == 1) PC = MAeff; else PC = PC; end
					JZ1: begin if (SR[8] == 1) PC = MAeff; else PC = PC; end
					JC0: begin if (SR[11] == 0) PC = MAeff; else PC = PC; end
					JN0: begin if (SR[10] == 0) PC = MAeff; else PC = PC; end
					JV0: begin if (SR[9] == 0) PC = MAeff; else PC = PC; end
					JZ0: begin if (SR[8] == 0) PC = MAeff; else PC = PC; end
					JU: begin PC = MAeff; end
					default: PC = PC;
				endcase end
//----------------------------------------------------------------------------
//ADD_IC, SUB_IC, ADDC_IC, SUBC_IC, NOT_IC, AND_IC, OR_IC, SRA_IC, RRC_IC:
			VADD_IC, VSUB_IC, ADD_IC, SUB_IC, ADDC_IC, SUBC_IC, NOT_IC, AND_IC, OR_IC, SRA_IC, RRC_IC, XOR_IC, SRL_IC, RRV_IC, RLN_IC, RLZ_IC, ROTR_IC, ROTL_IC:
				begin R[IR3[7:4]] = TALUH; SR = TSR; end
				
			MUL_IC, DIV_IC:
				begin
					R[IR3[7:4]] = TALUH;
					R[IR3[3:0]] = TALUL;
				end
		 default: ;
		endcase end
//----------------------------------------------------------------------------
// MC2 is executed second.
//----------------------------------------------------------------------------
	if (stall_mc2 == 0) begin
//----------------------------------------------------------------------------
		case (IR2[13:8])
			NOP_IC:begin
				nop_status = 1;
			end
			CFGDMA_IC: begin
				//DMA_write_out = 1;
				//DMA_select_out = Rj2;
				//DMA_data_out = T_DMA_data_out;
				DMA_write_out = 0;
			end
			SMXU_IC: begin
				Start_MXU_out = 1;
			end
			LD_IC, JMP_IC: begin 
//Address Arithmetic to calculate the effective address:
				MAeff = MAB + MAX;	
//For LD_IC we ensure here that WR_DM=0.
				WR_DM = 1'b0;	end 
//----------------------------------------------------------------------------
			ST_IC: begin 
//Address Arithmetic to calculate the effective address:
				MAeff = MAB + MAX;
// If the address points to a memory location, prepare to write to the DM:
				if (MAeff[13:4] != 10'h3FF) begin WR_DM = 1'b1;
// Next 3 lines below : DF-PU = Data Forwarding from the instruction in MC3:
// From the instruction that performs a WB:
	if (Rj2 == Ri3 && IR3[13:8] != (LD_IC || ST_IC || JMP_IC)) DM_in = R[Ri3];
// Next, resolve the SWAP WB:
	else if (Rj2 == Rj3 && IR3[13:8] == SWAP_IC) DM_in = R[Rj3];
// OR without DF.
	else DM_in = R[Rj2]; end end
//----------------------------------------------------------------------------
			CPY_IC: begin TALUL = TB; end
			SWAP_IC: begin TALUL = TA; TALUH = TB;end
			
			CALL_IC:
				begin				
					MAeff = MAB + MAX;
					DM_in = SR;
					SP = SP - 1'b1;
				end
			RET_IC:
				begin
					SP = SP + 1'b1;
					PC = DM_out;
				end
//----------------------------------------------------------------------------
// For all assignments that target TALUH we use TALUout.  This is 17-bits wide
// 	to account for the value of the carry when necessary.
//----------------------------------------------------------------------------
			ADD_IC, ADDC_IC: begin
					TALUout = TA + TB;
					TSR[11] = TALUout[14]; // Carry
					TSR[10] = TALUout[13]; // Negative
TSR[9] = ((TA[13] ~^ TB[13]) & TA[13]) ^ (TALUout[13] & (TA[13] ~^ TB[13])); // V Overflow
					if (TALUout[13:0] == 14'h0000) TSR[8] = 1; else TSR[8] = 0; // Zero
					TALUH = TALUout[13:0]; end
			SUB_IC, SUBC_IC: begin
					TALUout = TA - TB;
					TSR[11] = TALUout[14]; // Carry
					TSR[10] = TALUout[13]; // Negative
TSR[9] = ((TA[13] ~^ TB[13]) & TA[13]) ^ (TALUout[13] & (TA[13] ~^ TB[13])); // V Overflow
					if (TALUout[13:0] == 14'h0000) TSR[8] = 1; else TSR[8] = 0; // Zero
					TALUH = TALUout[13:0]; end
			VADD_IC:	begin
					TALUV_H = TA[13:7] + TB[13:7];
					TALUH[13:7] = TALUV_H[6:0];
					
					TSR[11] = TALUV_H[7]; // Carry
					TSR[10] = TALUV_H[6]; // Negative
					TSR[9] = ((TA[13] ~^ TB[13]) & TA[13]) ^ (TALUout[13] & (TA[13] ~^ TB[13])); // V Overflow
					if (TALUV_H[6:0] == 0) TSR[8] = 1; else TSR[8] = 0; // Zero
					
					TALUV_L = TA[6:0] + TB[6:0];
					TALUH[6:0] = TALUV_L[6:0];
					
					TSR[7] = TALUV_L[7]; // Carry
					TSR[6] = TALUV_L[6]; // Negative
					TSR[5] = ((TA[6] ~^ TB[6]) & TA[6]) ^ (TALUout[6] & (TA[6] ~^ TB[6])); // V Overflow
					if (TALUV_L[6:0] == 0) TSR[4] = 1; else TSR[4] = 0; // Zero
			end
			VSUB_IC:	begin
					TALUV_H = TA[13:7] - TB[13:7];
					TALUH[13:7] = TALUV_H[6:0];
					
					TSR[11] = TALUV_H[7]; // Carry
					TSR[10] = TALUV_H[6]; // Negative
					TSR[9] = ((TA[13] ~^ TB[13]) & TA[13]) ^ (TALUout[13] & (TA[13] ~^ TB[13])); // V Overflow
					if (TALUV_H[6:0] == 0) TSR[8] = 1; else TSR[8] = 0; // Zero
					
					TALUV_L = TA[6:0] - TB[6:0];
					TALUH[6:0] = TALUV_L[6:0];
					
					TSR[7] = TALUV_L[7]; // Carry
					TSR[6] = TALUV_L[6]; // Negative
					TSR[5] = ((TA[6] ~^ TB[6]) & TA[6]) ^ (TALUout[6] & (TA[6] ~^ TB[6])); // V Overflow
					if (TALUV_L[6:0] == 0) TSR[4] = 1; else TSR[4] = 0; // Zero
			end
					
					
					
			NOT_IC: begin
					TALUH = ~TA; //Carry and Overflow are not affected by ~
					TSR[10] = TALUH[13]; // Negative
					if (TALUout[13:0] == 14'h0000) TSR[8] = 1; else TSR[8] = 0; end // Zero
			AND_IC: begin
					TALUH = TA & TB; //Carry and Overflow are not affected by &
					TSR[10] = TALUH[13]; // Negative
					if (TALUout[13:0] == 14'h0000) TSR[8] = 1; else TSR[8] = 0; end // Zero
			OR_IC: begin
					TALUH = TA | TB; //Carry and Overflow are not affected by |
					TSR[10] = TALUH[13]; // Negative
					if (TALUout[13:0] == 14'h0000) TSR[8] = 1; else TSR[8] = 0; end // Zero
			XOR_IC: begin
					TALUH = TA ^ TB; //Carry and Overflow are not affected by |
					TSR[10] = TALUH[13]; // Negative
					if (TALUout[13:0] == 14'h0000) TSR[8] = 1; else TSR[8] = 0; end //zero
			SRA_IC: begin	
					TALUH = TA >>> Rj2;
					TSR[10] = TALUH[13]; // Negative
					if ( (TALUH[13:0] == 14'h0000) && (TALUL[13:0] == 14'h0000) ) TSR[8] = 1; else TSR[8] = 0; end // Zero
			SRL_IC:
				begin
					TALUH = TA >> Rj2;
					TSR[10] = TALUH[13]; // Negative
					if ( (TALUH[13:0] == 14'h0000) && (TALUL[13:0] == 14'h0000) ) TSR[8] = 1; else TSR[8] = 0; // Zero
				end
			RRC_IC: begin 	
					TALUH = TA >> Rj2;
					TSR[10] = TALUH[13]; // Negative
					if ( (TALUH[13:0] == 14'h0000) && (TALUL[13:0] == 14'h0000) ) TSR[8] = 1; else TSR[8] = 0; end // Zero
			RRV_IC:
				begin
					{TSR[9], TALUH} = {TSR[9], TA, TSR[9], TA} >> Rj2;
					TSR[10] = TALUH[13]; // Negative
					if ( (TALUH[13:0] == 14'h0000) && (TALUL[13:0] == 14'h0000) ) TSR[8] = 1; else TSR[8] = 0; // Zero
				end
			RLN_IC:
				begin
					{TALUH, TSR[10], TALUL, throwaway_bit} = {TA, TSR[10], TA, TSR[10]} << Rj2;
					TSR[10] = TALUH[13]; // Negative
					if ( (TALUH[13:0] == 14'h0000) && (TALUL[13:0] == 14'h0000) ) TSR[8] = 1; else TSR[8] = 0; // Zero
				end
			RLZ_IC:
				begin
					{TALUH, TSR[8], TALUL, throwaway_bit} = {TA, TSR[8], TA, TSR[8]} << Rj2;
					TSR[10] = TALUH[13]; // Negative
					if ( (TALUH[13:0] == 14'h0000) && (TALUL[13:0] == 14'h0000) ) TSR[8] = 1; else TSR[8] = 0; // Zero
				end
			ROTR_IC:
				begin 
					TALUH = {TA, TA, TA} >> Rj2;
					TSR[10] = TALUH[13]; // Negative
					if ( (TALUH[13:0] == 14'h0000) && (TALUL[13:0] == 14'h0000) ) TSR[8] = 1; else TSR[8] = 0; // Zero
				end
			ROTL_IC:
				begin
					TALUH = {TA, TA, TA} >> (4'b1110 - Rj2);
					TSR[10] = TALUH[13]; // Negative
					if ( (TALUH[13:0] == 14'h0000) && (TALUL[13:0] == 14'h0000) ) TSR[8] = 1; else TSR[8] = 0; // Zero
				end
			MUL_IC:
				begin
					{TALUH, TALUL} = TA * TB; //MULT // $finish, $stop, $display, $rand, $urand, $log, $real
					TSR[10] = TALUH[13]; // Negative
					if ( (TALUH[13:0] == 14'h0000) && (TALUL[13:0] == 14'h0000) ) TSR[8] = 1; else TSR[8] = 0; // Zero
				end
			DIV_IC:
				begin
					TALUH = TA / TB; //div
					TALUL = TA % TB; //remainder
					TSR[10] = TALUH[13]; // Negative
					if ( (TALUH[13:0] == 14'h0000) && (TALUL[13:0] == 14'h0000) ) TSR[8] = 1; else TSR[8] = 0; // Zero
				end	
					
					
					
			 default: ;	//If there's a problem with decoding the OpCode ...;
								//Useful in debugging through simulation
		endcase end
//----------------------------------------------------------------------------
// MC1 is executed third.
//----------------------------------------------------------------------------
	if (stall_mc1 == 0) begin
//----------------------------------------------------------------------------
// For LD, ST, and JMP my address offset is IW1, i.e. I need to fetch IW1 in 
// MC1, and assign the right values to MAB and MAX
//----------------------------------------------------------------------------
		case (IR1[13:8])
			NOP_IC:begin
				nop_status = 1;
			end
			CFGDMA_IC: begin
				if (Ri1 == 0) DMA_data_out = PM_out; 
				else	
				begin
					if (Ri1 == Ri2) DMA_data_out = PM_out + TALUH; 
					else if ((IR2[13:8] != ADDC_IC && IR2[13:8] != SUB_IC) && (IR2[13:8] == MUL_IC || IR2[13:8] == DIV_IC || IR2[13:8] == SWAP_IC) && Ri1 == Rj2) DMA_data_out = PM_out + TALUL;
					else DMA_data_out = PM_out + R[Ri1];
				end
				DMA_write_out = 1;
				DMA_select_out = Rj1;
				PC = PC + 1'b1;
			end
			SMXU_IC: begin
				Start_MXU_out = 0;
			end
			
			LD_IC, ST_IC, JMP_IC: begin
// Load MAB with the base address constant value read from the next location 
// in the PM; a value of 0 emulates the Register Indirect AM.
				MAB = PM_out;
				DM_ctrl = 1'b0;

// Load MAX with index value; this can be changed at run-time/ dynamically;
// a value of 0 emulates the Direct AM.
				if (Ri1 == 0) MAX = 0; 
				else if (Ri1 == 1) MAX = PC;
				else if (Ri1 == 2) MAX = SP;
				else if (Ri1 == Ri2)	
					begin
						if((IR2[13:8] == MUL_IC || IR2[13:8] == DIV_IC || IR2[13:8] == SWAP_IC))
							MAX = TALUL;
						else
							MAX = TALUH; // <-- DF-FU = Data Forwarding 
					end
				else MAX = R[Ri1]; 				// from the instruction in MC2
				
//Increment the PC to point to the location of the next IW.
				PC = PC + 1'b1;
				
			end
				
			CALL_IC: begin
				PC = PC + 1'b1;
				MAB = PM_out;
				

				if (Ri1 == 0) MAX = 0; 
				else if (Ri1 == 1) MAX = PC;
				else if (Ri1 == 2) MAX = SP;
				else if (Ri1 == Ri2)	
					begin
						if((IR2[13:8] == MUL_IC || IR2[13:8] == DIV_IC || IR2[13:8] == SWAP_IC))
							MAX = TALUL;
						else
							MAX = TALUH; // <-- DF-FU = Data Forwarding 
					end
				else MAX = R[Ri1]; 				// from the instruction in MC2
					
	//Increment the PC to point to the location of the next IW.
					DM_in = PC;
					WR_DM = 1'b1;
					DM_ctrl = 1'b1;
					SP = SP - 1;
			
			end
			
			RET_IC: begin
			
				DM_ctrl = 1'b1;
				SP = SP + 1'b1;
				SR = DM_out;

			
			end
//----------------------------------------------------------------------------
			CPY_IC: begin
				if (Rj1 == Ri2)	TB = TALUH; // <-- DF-FU = Data Forwarding from
				else TB = R[Rj1];	end			// the instruction in MC2
			/*NOT_IC, SRA_IC, RRC_IC, SRL_IC, RRV_IC, RLN_IC, RLZ_IC, ROTL_IC, ROTR_IC: begin
				if (Ri1 == Ri2)	TA = TALUH; // <-- DF-FU = Data Forwarding from
				else TA = R[Ri1];	end			// the instruction in MC2*/
			ADDC_IC, SUBC_IC: begin
				if (Ri1 == Ri2)
					begin
						if ((IR2[13:8] == MUL_IC || IR2[13:8] == DIV_IC || IR2[13:8] == SWAP_IC))
							TA = TALUL;
						else
							TA = TALUH;
					end// <-- DF-FU
				else TA = R[Ri1]; TB = {10'b0000000000, IR1[3:0]}; end
		default: begin	// SWAP_IC, ADD_IC, SUB_IC, AND_IC, OR_IC:
// DF-FU; Ri2 below is right for every previous instruction that returns a 
// result in Ri2; need to modify for a previous SWAP if the value is to be Rj2			
			if (Ri1 == Ri2) TA = TALUH; 
			else if ((IR2[13:8] != ADDC_IC && IR2[13:8] != SUB_IC) && (IR2[13:8] == MUL_IC || IR2[13:8] == DIV_IC || IR2[13:8] == SWAP_IC) && Ri1 == Rj2) TA = TALUL;
			else TA = R[Ri1];
			
			if (Rj1 == Ri2) TB = TALUH; 
			else if ((IR2[13:8] != ADDC_IC && IR2[13:8] != SUB_IC) && (IR2[13:8] == MUL_IC || IR2[13:8] == DIV_IC || IR2[13:8] == SWAP_IC) && Rj1 == Rj2) TB = TALUL;
			else TB = R[Rj1]; 
			
			end
		endcase
	end
//----------------------------------------------------------------------------
// The only data D/H that can occur are RAW.  These are automatically 
//		resolved.  In the case of the JUMPS we stall until the adress of the
//		next instruction to be executed is known.
// The IR value 0xffff I call a "don't care" OpCode value.  It allows us to
//		control the refill of the pipe after the stalls of a jump emptied it.
//----------------------------------------------------------------------------
// Instruction in MC2 can move to MC3; Below: Rj3 = Ri3 because the previous 
// instruction returns a result in Ri2; need to modify for a previous SWAP
		if (stall_mc2 == 0 && IR3[13:8] != JMP_IC && (IR3[13:8] != CALL_IC) && (IR3[13:8] != RET_IC) //&& (IR3[13:8] != LDDMA_IC) && (IR3[13:8] != LADMA_IC) && (IR3[13:8] != STDMA_IC)
		) 
		begin IR3 = IR2; Ri3 = Ri2; Rj3 = Rj2; stall_mc3 = 0; end 
// Instruction in MC2 is stalled and IR3 is loaded with the "don't care IW"	
		else begin stall_mc2 =1; IR3 = 14'h3fff; Ri3=102; Rj3=302; end 
//----------------------------------------------------------------------------
// Instruction in MC1 can move to MC2; Rj2 may need to be = Ri1 for certain 
// instruction sequences	
	if (stall_mc1 == 0 
	&& (IR2[13:8] != JMP_IC) && (IR3[13:8] != JMP_IC)
	&& (IR2[13:8] != CALL_IC) && (IR3[13:8] != CALL_IC)
	&& (IR2[13:8] != RET_IC) && (IR3[13:8] != RET_IC)
	//&& (IR2[13:8] != LDDMA_IC) && (IR3[13:8] != LDDMA_IC)
	//&& (IR2[13:8] != LADMA_IC) && (IR3[13:8] != LADMA_IC)
	//&& (IR2[13:8] != STDMA_IC) && (IR3[13:8] != STDMA_IC)
	) 
		begin IR2 = IR1; Ri2 = Ri1; Rj2 = Rj1; stall_mc2 = 0; end
// Instruction in MC1 is stalled and IR2 is loaded with the "don't care IW"	
	else begin stall_mc1 = 1; IR2 = 14'h3fff; Ri2=101; Rj2=301;  end 
//----------------------------------------------------------------------------
// Instruction in MC0 can move to MC1; 	
	if ((stall_mc0 == 0) && (IR1[13:8] != JMP_IC) && (IR2[13:8] != JMP_IC) && (IR3[13:8] != JMP_IC)
	&& (IR1[13:8] != LD_IC) 
	&& (IR1[13:8] != ST_IC)
	&& (IR1[13:8] != CFGDMA_IC)
	&& (IR1[13:8] != CALL_IC) && (IR2[13:8] != CALL_IC) && (IR3[13:8] != CALL_IC) 
	&& (IR1[13:8] != RET_IC) && (IR2[13:8] != RET_IC) && (IR3[13:8] != RET_IC)
	//&& (IR1[13:8] != LDDMA_IC) && (IR2[13:8] != LDDMA_IC) && (IR3[13:8] != LDDMA_IC)
	//&& (IR1[13:8] != LADMA_IC) && (IR2[13:8] != LADMA_IC) && (IR3[13:8] != LADMA_IC)
	//&& (IR1[13:8] != STDMA_IC) && (IR2[13:8] != STDMA_IC) && (IR3[13:8] != STDMA_IC)
	) 
// Below: IW0 is fetched directly into IR1, Ri1, and Rj1
		begin IR1 = PM_out; Ri1 = PM_out[7:4];
		Rj1 = PM_out[3:0]; PC = PC + 1'b1; stall_mc1 = 0; end 
// Instruction in MC0 is stalled and IR1 is loaded with the "don't care IW"	
	else begin stall_mc0 = 1; IR1 = 14'h3fff;  Ri1=100; Rj1=300; end 
//----------------------------------------------------------------------------
// After the JMP_IC instruction reaches MC3 OR (LD_IC or ST_C) reach MC1,
// start refilling the pipe by removing the stalls. For JMP_IC the stalls are 
// removed in this order: stall_mc0 --> stall_mc1 --> stall_mc2
	if ((IR3 == 14'h3fff) | (IR2[13:8] == LD_IC) | (IR2[13:8] == ST_IC)) 
		stall_mc0 = 0; 
//----------------------------------------------------------------------------
	end
	

	
	end
endmodule

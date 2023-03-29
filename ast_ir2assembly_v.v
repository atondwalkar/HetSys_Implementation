module ast_ir2assembly_v (IR, Resetn_pin, Clock_pin, ICis);
//=============================================================================
// This module is converting the IW information into a string of ASCII 
// characters. This is ONLY needed for debugging purposes. It should be 
// commented out or eliminated when compiling/ synthesizing for FPGA 
// implementation. It is described behaviorally. In the ModelSim wavform, 
// select the display radix for this output signal to be ASCII.
//=============================================================================	
// Input and output ports declarations
//=============================================================================	
input [15:0] IR;
input Resetn_pin, Clock_pin;
output reg [95:0] ICis;
//=============================================================================
// Internal wires declarations
//=============================================================================
reg [7:0] IR11to6, IR5to0, sbit, sbit_val;
//=============================================================================
always @ (posedge Clock_pin) begin
//=============================================================================
// Converting register numbers to ASCII digit character numbers
//=============================================================================
if(IR[7:4] < 10)
begin
	IR11to6 = 8'h30 + {4'b0000, IR[7:4]};
end
else
begin
	IR11to6 = 8'h41 + {4'b0000, IR[7:4]-10};
end

if(IR[3:0] < 10)
begin
	IR5to0 = 8'h30 + {4'b0000, IR[3:0]};
end
else
begin
	IR5to0 = 8'h41 + {4'b0000, IR[3:0]-10};
end


//=============================================================================
// Similarly for the status bit and status bit value 
// used in the (conditional) JUMP
//=============================================================================
if 		(IR[3:0] == 4'b0000) begin sbit = 8'h55; sbit_val = 8'h20; end
else if 	(IR[3:0] == 4'b1000) begin sbit = 8'h43; sbit_val = 8'h31; end
else if 	(IR[3:0] == 4'b0100) begin sbit = 8'h4E; sbit_val = 8'h31; end
else if 	(IR[3:0] == 4'b0010) begin sbit = 8'h56; sbit_val = 8'h31; end
else if 	(IR[3:0] == 4'b0001) begin sbit = 8'h5A; sbit_val = 8'h31; end
else if 	(IR[3:0] == 4'b0111) begin sbit = 8'h43; sbit_val = 8'h30; end
else if 	(IR[3:0] == 4'b1011) begin sbit = 8'h4E; sbit_val = 8'h30; end
else if 	(IR[3:0] == 4'b1101) begin sbit = 8'h56; sbit_val = 8'h30; end
else if 	(IR[3:0] == 4'b1110) begin sbit = 8'h5A; sbit_val = 8'h30; end
else begin sbit = 8'h3f; sbit_val = 8'h3f; end
//=============================================================================
// After the IR (IW) is passed on to the CU in MC1, the current IC/IW can be 
// idenitified and the corresponding assembly instruction displayed.
//=============================================================================
if (Resetn_pin == 1'b0)
	ICis = {8'h52, 8'h53, 8'h54, 8'h20}; //RST;
else case (IR[13:8])
	6'b000000 : ICis = {8'h4C, 8'h44, 8'h20, 8'h52, IR5to0, 8'h2c, 8'h20, 8'h4D, 8'h41,  8'h72, IR11to6, 8'h3B}; //LD
	6'b000001 : ICis = {8'h53, 8'h54, 8'h20, 8'h52, IR5to0, 8'h2c, 8'h20, 8'h4D, 8'h41,  8'h72, IR11to6, 8'h3B}; //ST
	6'b000010 : ICis = {8'h43, 8'h50, 8'h59, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //CPY
	6'b000011 : ICis = {8'h53, 8'h57, 8'h41, 8'h50, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //SWAP
	6'b000100 : ICis = {8'h4A, 8'h55, 8'h4D, 8'h50, 8'h20, 8'h69, 8'h66, 	8'h20, sbit,  8'h3D, sbit_val,  8'h3B}; //JUMP
	6'b000101 : ICis = {8'h41, 8'h44, 8'h44, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //ADD
	6'b000110 : ICis = {8'h53, 8'h55, 8'h42, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //SUB
	6'b000111 : ICis = {8'h41, 8'h44, 8'h44, 8'h43, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //ADDC
	6'b001000 : ICis = {8'h53, 8'h55, 8'h42, 8'h43, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //SUBC
	6'b001001 : ICis = {8'h4E, 8'h4F, 8'h54, 8'h20, 8'h20, 8'h52, IR11to6, 8'h20, 8'h20, 8'h20, 8'h20,  8'h3B}; //NOT
	6'b001010 : ICis = {8'h41, 8'h4E, 8'h44, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //AND
	6'b001011 : ICis = {8'h4F, 8'h52, 8'h20, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //OR
	6'b001100 : ICis = {8'h53, 8'h52, 8'h41, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //SRA
	6'b001101 : ICis = {8'h53, 8'h52, 8'h4C, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //SRL
	6'b001110 : ICis = {8'h56, 8'h41, 8'h44, 8'h44, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //VADD
	6'b001111 : ICis = {8'h56, 8'h53, 8'h55, 8'h42, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //VSUB
	6'b010000 : ICis = {8'h4D, 8'h55, 8'h4C, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //MUL
	6'b010001 : ICis = {8'h44, 8'h49, 8'h56, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //DIV
	6'b010010 : ICis = {8'h58, 8'h4F, 8'h52, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //XOR
	6'b010011 : ICis = {8'h52, 8'h4F, 8'h54, 8'h4C, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //ROTL
	6'b010100 : ICis = {8'h52, 8'h4F, 8'h54, 8'h52, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //ROTR
	6'b010101 : ICis = {8'h52, 8'h4C, 8'h5A, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //RLZ
	6'b010110 : ICis = {8'h52, 8'h4C, 8'h4E, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //RLN
	6'b010111 : ICis = {8'h52, 8'h52, 8'h43, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //RRC
	6'b011000 : ICis = {8'h52, 8'h52, 8'h56, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //RRV
	6'b011001 : ICis = {8'h43, 8'h41, 8'h4C, 8'h4C, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //CALL
	6'b011010 : ICis = {8'h52, 8'h45, 8'h54, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //RET
	6'b011011 : ICis = {"CFGDMA", 8'h20, 8'h52, IR11to6, 8'h20, 8'h20, 8'h20}; //CFGDMA
	6'b011100 : ICis = {"SMXU", 8'h20, 8'h52, IR11to6, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}; //SMXU
	6'b011101 : ICis = {"CMXU", 8'h20, 8'h52, IR11to6, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20};
	6'b111110 : ICis = {"NOP", 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}; //NOP
	6'b111111 : ICis = {8'h53, 8'h54, 8'h41, 8'h4C, 8'h4C, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}; //STALL
	
	default : ICis = {8'h4E, 8'h44, 8'h45, 8'h46}; //NDEF
	endcase
end
endmodule


/*module dxp_ir2assembly_v (IR, Resetn_pin, Clock_pin, ICis);
//=============================================================================
// This module is converting the IW information into a string of ASCII 
// characters. This is ONLY needed for debugging purposes. It should be 
// commented out or eliminated when compiling/ synthesizing for FPGA 
// implementation. It is described behaviorally. In the ModelSim wavform, 
// select the display radix for this output signal to be ASCII.
//=============================================================================	
// Input and output ports declarations
//=============================================================================	
input [15:0] IR;
input Resetn_pin, Clock_pin;
output reg [95:0] ICis;
//=============================================================================
// Internal wires declarations
//=============================================================================
reg [7:0] IR11to6, IR5to0, sbit, sbit_val;
//=============================================================================
always @ (posedge Clock_pin) begin
//=============================================================================
// Converting register numbers to ASCII digit character numbers
//=============================================================================
IR11to6 = 8'h30 + {2'b00, IR[11:6]};
IR5to0 = 8'h30 + {2'b00, IR[5:0]};
//=============================================================================
// Similarly for the status bit and status bit value 
// used in the (conditional) JUMP
//=============================================================================
if 		(IR[3:0] == 4'b0000) begin sbit = 8'h55; sbit_val = 8'h20; end
else if 	(IR[3:0] == 4'b1000) begin sbit = 8'h43; sbit_val = 8'h31; end
else if 	(IR[3:0] == 4'b0100) begin sbit = 8'h4E; sbit_val = 8'h31; end
else if 	(IR[3:0] == 4'b0010) begin sbit = 8'h56; sbit_val = 8'h31; end
else if 	(IR[3:0] == 4'b0001) begin sbit = 8'h5A; sbit_val = 8'h31; end
else if 	(IR[3:0] == 4'b0111) begin sbit = 8'h43; sbit_val = 8'h30; end
else if 	(IR[3:0] == 4'b1011) begin sbit = 8'h4E; sbit_val = 8'h30; end
else if 	(IR[3:0] == 4'b1101) begin sbit = 8'h56; sbit_val = 8'h30; end
else if 	(IR[3:0] == 4'b1110) begin sbit = 8'h5A; sbit_val = 8'h30; end
else begin sbit = 8'h3f; sbit_val = 8'h3f; end
//=============================================================================
// After the IR (IW) is passed on to the CU in MC1, the current IC/IW can be 
// idenitified and the corresponding assembly instruction displayed.
//=============================================================================
if (Resetn_pin == 1'b0)
	ICis = {8'h52, 8'h53, 8'h54, 8'h20}; //RST;
else if (IR == 16'hffff)
	ICis = {8'h53, 8'h54, 8'h41, 8'h4C, 8'h4C, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}; //STALL
else case (IR[15:12])
	4'b0000 : ICis = {8'h4C, 8'h44, 8'h20, 8'h52, IR5to0, 8'h2c, 8'h20, 8'h4D, 8'h41,  8'h72, IR11to6, 8'h3B}; //LD
	4'b0001 : ICis = {8'h53, 8'h54, 8'h20, 8'h52, IR5to0, 8'h2c, 8'h20, 8'h4D, 8'h41,  8'h72, IR11to6, 8'h3B}; //ST
	4'b0010 : ICis = {8'h43, 8'h50, 8'h59, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //CPY
	4'b0011 : ICis = {8'h53, 8'h57, 8'h41, 8'h50, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //SWAP
	4'b0100 : ICis = {8'h4A, 8'h55, 8'h4D, 8'h50, 8'h20, 8'h69, 8'h66, 	8'h20, sbit,  8'h3D, sbit_val,  8'h3B}; //JUMP
	4'b0101 : ICis = {8'h41, 8'h44, 8'h44, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //ADD
	4'b0110 : ICis = {8'h53, 8'h55, 8'h42, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //SUB
	4'b0111 : ICis = {8'h41, 8'h44, 8'h44, 8'h43, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //ADDC
	4'b1000 : ICis = {8'h53, 8'h55, 8'h42, 8'h43, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //SUBC
	4'b1001 : ICis = {8'h4E, 8'h4F, 8'h54, 8'h20, 8'h20, 8'h52, IR11to6, 8'h20, 8'h20, 8'h20, 8'h20,  8'h3B}; //NOT
	4'b1010 : ICis = {8'h41, 8'h4E, 8'h44, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //AND
	4'b1011 : ICis = {8'h4F, 8'h52, 8'h20, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //OR
	4'b1100 : ICis = {8'h53, 8'h52, 8'h41, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //SRA
	4'b1101 : ICis = {8'h52, 8'h52, 8'h43, 8'h20, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h23, IR5to0, 8'h3B}; //RRC
	4'b1110 : ICis = {8'h56, 8'h41, 8'h44, 8'h44, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //VADD
	4'b1111 : ICis = {8'h56, 8'h53, 8'h55, 8'h42, 8'h20, 8'h52, IR11to6, 8'h2c, 8'h20, 8'h52, IR5to0, 8'h3B}; //VSUB
	default : ICis = {8'h4E, 8'h44, 8'h45, 8'h46}; //NDEF
	endcase
end
endmodule*/

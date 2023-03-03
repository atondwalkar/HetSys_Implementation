module ast_2to4_dec (data_in, eq);

input [1:0] data_in;
output reg	[3:0] eq;

always @ (data_in)
	case (data_in)
		2'b00: eq = 4'b0001;
		2'b01: eq = 4'b0010;
		2'b10: eq = 4'b0100;
		2'b11: eq = 4'b1000;
		default: eq = 4'b0000;
	endcase
endmodule

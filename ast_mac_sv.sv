`timescale 1ns / 1ps

//N-bit int multiplay accumulate unit

module ast_mac_sv(
    a_in,
    b_in,
    clk,
    mult_en,
    acc_en,
    load_en,
    reset,
    acc_out,
    a_out,
    b_out
    );
	 
	 parameter DATAWIDTH = 14;
    
    input [DATAWIDTH-1:0] a_in, b_in;
    input clk, mult_en, acc_en, load_en, reset;
    output reg [(DATAWIDTH*2)-1:0] acc_out;
    output reg [DATAWIDTH-1:0] a_out, b_out;
    
    reg [(DATAWIDTH*2)-1:0] mult;
    
    always @ (posedge clk)
    begin
        if(reset)
        begin
            a_out <= 0;
            b_out <= 0;
            acc_out <= 0;
            mult <= 0;
        end
        else
        begin
            a_out <= load_en ? a_in : a_out;
            b_out <= load_en ? b_in : b_out;
            mult <= mult_en ? a_out*b_out : mult;
            acc_out <= acc_en ? mult + acc_out : acc_out;
        end
    end 
    
endmodule

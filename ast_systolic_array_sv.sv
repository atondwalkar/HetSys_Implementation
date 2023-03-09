`timescale 1ns / 1ps

module ast_systolic_array_sv(
    a_in,
    b_in,
    mult_en,
    acc_en,
    load_en,
    clk,
    reset,
    d_out,
    );
    
    parameter SIZE = 4; //systolic array size SIZE x SIZE
	 parameter DATAWIDTH = 14; //data bus width
    
    input logic clk, reset, mult_en, acc_en, load_en;
    input logic [DATAWIDTH-1:0] a_in [SIZE-1:0]; //data input from row fifo set
    input logic [DATAWIDTH-1:0] b_in [SIZE-1:0]; //data input from col fifo set
    output logic [DATAWIDTH-1:0] d_out [SIZE-1:0][SIZE-1:0];
	 
    
    logic [DATAWIDTH-1:0] a [SIZE:0][SIZE:0]; //internal array row connections
    logic [DATAWIDTH-1:0] b [SIZE:0][SIZE:0]; //internal array col connections

    integer k;
    always_comb
    begin
        for(k=0; k<SIZE; k++) //initial connections to internal wires
        begin
            a[k][0] = a_in[k]; //row boundary
            b[0][k] = b_in[k]; //col boundary
        end
    end
    
    genvar i, j;
    generate //the systolic array instantiation
    for (i=0; i<SIZE; i++)
    begin : rows
        for (j=0; j<SIZE; j++) 
        begin : cols
            ast_mac_sv element ( 
                .clk(clk), 
                .reset(reset), 
                .a_in(a[i][j]), 
                .b_in(b[i][j]), 
                .mult_en(mult_en), 
                .acc_en(acc_en), 
                .load_en(load_en), 
                .a_out(a[i][j+1]), 
                .b_out(b[i+1][j]),
                .acc_out(d_out[i][j])
                );
        end
    end 
    endgenerate
    
endmodule

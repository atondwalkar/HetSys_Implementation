`timescale 1ns / 10ps


module tensor_system_tb_sv;

    parameter SIZE = 4;
	 parameter DATAWIDTH = 14;

    logic clk, reset;

/* 
	 
    logic wready, arready;
    logic [7:0] wdata;
    logic [31:0] awaddr;
    logic [31:0] rdata;
    logic [31:0] araddr;

  
	mxu #(.SIZE(SIZE)) DUT (
        .clk(clk),
        .reset(reset),
        .wdata(wdata),
        .awaddr(awaddr),
        .wready(wready),
        .rdata(rdata),
        .araddr(araddr),
        .arready(arready)
    );
*/
	
	logic [$clog2(SIZE):0] depth, width;
	logic [$clog2(SIZE)-1:0] cycles_in;
	logic [DATAWIDTH-1:0] data_in, data_out;
	logic wen, ren, set, relu, start, busy;
	
   logic [SIZE-1:0][SIZE-1:0][DATAWIDTH-1:0] matrix_a = '{'{5, 2, 6, 1},'{0, 6, 2, 0},'{3, 8, 1, 4},'{1, 8, 5, 6}};
   logic [SIZE-1:0][SIZE-1:0][DATAWIDTH-1:0] matrix_b = '{'{7, 5, 8, 0},'{1, 8, 2, 6},'{9, 4, 3, 8},'{5, 3, 7, 9}};
	
	ast_tensor_system_sv #(.SIZE(SIZE), .DATAWIDTH(DATAWIDTH)) DUT (
		.clk(clk), 
		.reset(reset),
		.depth(depth),
		.width(width),
		.data_in(data_in),
		.wen(wen),
		.ren(ren),
		.set(set),
		.relu(relu),
		.start(start),
		.busy(busy),
		.data_out(data_out)
	);
	
	
	
   integer i, j, k;


	initial begin 
		clk = 0;
		forever begin
		#10 clk = ~clk;
	end end 	
	 
	initial begin
		reset = 1;
		ren = 0;
		start = 0;
		set = 0;
		relu = 0;
		width = 0;
		depth = 0;
		data_in = 0;
		#45;
		reset = 0;
		wen = 1;
		width = 3'b100;
		depth = 3'b100;
		for(i = 0; i < SIZE; i++)
		begin
			 for(j = 0; j < SIZE; j++)
				  begin
						data_in = matrix_a[SIZE-i-1][SIZE-j-1];
						#20;
				  end
		end
		wen = 0;
		#100;
		
		set = 1;
		wen = 1;
		for(i = 0; i < SIZE; i++)
		begin
			 for(j = 0; j < SIZE; j++)
				  begin
						data_in = matrix_b[SIZE-i-1][SIZE-j-1];
						#20;
				  end
		end
		wen = 0;
		#100;
		
		start = 1;
		
		#100;
		
		start = 0;
		
		#1005;
		
		ren = 1;
		
		#1000;
	
		$stop;
	
	end
	 
	 
/*


    initial
    begin

        //setting signals low
        clk = 0;
        reset = 1;
        araddr = 0;
        wready = 0;
        awaddr = 0;
        arready = 0;

        //reset system
        #10;
        clk = 1;
        #10
        clk = 0;
        reset = 0;

        //loading data to A

        for(i = 0; i < SIZE; i++)
            begin
                for(j = 0; j < SIZE; j++)
                    begin
                        #10;
                        clk = 1;
                        awaddr = 2 + j + i*SIZE;
                        #10;
                        clk = 0;
                        #10;
                        clk = 1;
                        #10;
                        clk = 0;
                        wdata = matrix_a[SIZE-i-1][SIZE-j-1];
                        wready = 1;
                        #10;
                        clk = 1;
                        #10;
                        clk = 0;
                        wready = 0;
                        #10;
                        clk = 1;
                        #10;
                        clk = 0;
                        #10;
                    end
            end

            //loading data to B

        for(i = 0; i < SIZE; i++)
            begin
                for(j = 0; j < SIZE; j++)
                    begin
                        #10;
                        clk = 1;
                        awaddr = 2 + SIZE*SIZE + j + i*SIZE;
                        #10;
                        clk = 0;
                        #10;
                        clk = 1;
                        #10;
                        clk = 0;
                        wdata = matrix_b[SIZE-i-1][SIZE-j-1];
                        wready = 1;
                        #10;
                        clk = 1;
                        #10;
                        clk = 0;
                        wready = 0;
                        #10;
                        clk = 1;
                        #10;
                        clk = 0;
                        #10;
                    end
            end

            //setting how many cycles
        #10;
        clk = 0;
        awaddr = 1;
        #10;
        clk = 1;
        #10;
        clk = 0;
        wdata = 20;
        wready = 1;
        #10;
        clk = 1;
        #10;
        clk = 0;
        wready = 0;
        awaddr = 0;
        #10;
        clk = 1;
        #10;
        clk = 0;
        #10;

        //start matrix multiplication    
        #10;
        clk = 0;
        wdata = 8'b0000_0001;
        wready = 1;
        #10;
        clk = 1;
        #10;
        clk = 0;
        wready = 0;
        #10;
        for(k = 0; k < 20*3 + 5; k++)
            begin
                #10;
                clk = 1;
                #10;
                clk = 0;
            end
        

            //read from accumulator
        for(k = 0; k < SIZE*SIZE; k++)
            begin
                #10;
                clk = 1;
                #10;
                clk = 0;
                araddr = 1 + k;
                arready = 1;
                #10;
                clk = 1;
                #10;
                clk = 0;
                arready = 0;
                #10;
                clk = 1;
                #10;
                clk = 0;
                #10;
                clk = 1;
                #10;
                clk = 0;
            end


        $finish;


    end

	 */

endmodule

/*

Copyright (c) 2021 Alex Pahmutov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

`timescale 1ns/1ps

module sim_ram;
	
	function integer clogb2;
   	input [31:0] value;
   	begin
        value = value - 1;
        for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
            value = value >> 1;
        end
   	end
	endfunction
	
	localparam period = 10;
	localparam DATA_WIDTH = 12;  
	localparam RAM_DEPTH = 4096;  
	localparam ADDR_WIDTH = clogb2(RAM_DEPTH);
	
	// Inputs
	reg clk;
	reg rst_n;
	reg write_enable;
	reg [DATA_WIDTH - 1:0] data_in;
	reg [ADDR_WIDTH - 1:0] address;

	// Outputs
	wire [DATA_WIDTH - 1:0] data_out;

	// Instantiate the Unit Under Test (UUT)
	single_port_ram #
	(
		.DATA_WIDTH(DATA_WIDTH),
		.RAM_DEPTH(RAM_DEPTH)
	)
	uut 
	(
		.clk(clk), 
		.rst_n(rst_n), 
		.write_enable(write_enable), 
		.data_in(data_in), 
		.address(address), 
		.data_out(data_out)
	);
	
	always #period  clk = !clk;
	
	initial begin
		clk = 0;
		rst_n = 0;
		write_enable = 0;
		
		data_in = 0;
		address = 0;
		
		#100;
		clk = 1;
		write_enable = 0;
		
        
	end
      
endmodule
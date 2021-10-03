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

`timescale 1ns / 1ps

module hdmi_rx (
    input   wire reset,          // rx reset
    input   wire pclk,           // regenerated pixel clock

    input   wire hsync,          // hsync data
    input   wire vsync,          // vsync data
    input   wire de,             // data enable
  
    input   wire blue_vld,
    input   wire green_vld,
    input   wire red_vld,
    input   wire blue_rdy,
    input   wire green_rdy,
    input   wire red_rdy,

    input   wire [7:0] red,      // pixel data out
    input   wire [7:0] green,    // pixel data out
    input   wire [7:0] blue,

    output  wire [23:0]   fifo_data_in,
    output  wire          fifo_write_enable   
);

localparam [3:0]
    STATE_WAIT_CALIB = 4'd0,
    STATE_WRITE = 4'd1,
    STATE_WAIT = 4'd2;

reg [3:0] state_reg;

always @(posedge clk) begin
	if (rst) begin
        state_reg <= STATE_WAIT_CALIB;

	end else begin
		case (state_reg)
			STATE_WAIT_CALIB: begin

			end
            STATE_WRITE: begin

            end
		endcase
	end
end
endmodule
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

// Language: Verilog 2001

`timescale 1ns / 1ps

module uart_control
(
    input   wire          clk,
    input   wire          rst,

    input   wire [7:0]  rx_fifo_data,
    output  wire        rx_fifo_read_enable,
    input   wire        rx_fifo_full,
    input   wire        rx_fifo_empty,
    input   wire [5:0]  rx_fifo_data_count,

    output  wire        start_write_frame
);

localparam [3:0]
    WAIT_COMMAND = 4'd0;
    READ_FIFO_DATA = 4'd1,
    SEND_START_COMMAND = 4'd2;

reg [3:0] state_reg;

always @(posedge clk) begin
	if (rst) begin
        state_reg <= WAIT_COMMAND;

	end else begin
		case (state_reg)
			WAIT_COMMAND: begin
                if(!rx_fifo_empty)
                    state_reg <= READ_FIFO_DATA;
                else
                    state_reg <= WAIT_COMMAND;
			end
            READ_FIFO_DATA: begin
                
            end
            SEND_START_COMMAND: begin
                
            end
		endcase
	end
end

endmodule
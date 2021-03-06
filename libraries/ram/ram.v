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

`timescale 1us/1ns

module single_port_ram#
(
    parameter DATA_WIDTH = 8,
    parameter RAM_DEPTH =  1024,
    parameter ADDR_WIDTH = $clog2(RAM_DEPTH) 
)
(
    input wire clk,
    input wire rst_n,

    input wire write_enable,
    input [DATA_WIDTH - 1:0] data_in,
    input [ADDR_WIDTH - 1:0] address,
    output reg [DATA_WIDTH - 1:0] data_out
);

reg [DATA_WIDTH - 1:0] ram [2**ADDR_WIDTH-1:0];

always @(posedge clk) begin
    if(write_enable) begin
        ram[address] <= data_in;
        data_out <= data_in;
    end else
        data_out <= ram[address];
end

endmodule
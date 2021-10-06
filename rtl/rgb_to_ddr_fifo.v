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

module rgb_to_ddr_fifo# (
    // RED 8 bit, Green 8 bit, Blue 8 bit
    parameter RGB_WIDTH = 24,
    // RGB Receive fifo depth 
    parameter FIFO_DEPTH = 4096,
    parameter DATA_COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1
)
(
    input  wire                     ddr_clk,
    input  wire                     ddr_rst,
    
    input  wire                     hdmi_pixel_clk,
    input  wire                     hdmi_pixel_rst,

    input  wire [RGB_WIDTH - 1:0]   fifo_data_in,
    input  wire                     fifo_write_enable

);

wire 								fifo_read_enable;
wire [RGB_WIDTH - 1:0]              fifo_data_out;
wire [DATA_COUNT_WIDTH - 1:0]       fifo_wr_data_count;
wire [DATA_COUNT_WIDTH - 1:0]       fifo_rd_data_count;
wire                                fifo_overflow;
wire                                fifo_underflow;
wire                                fifo_full;
wire                                fifo_empty;

rbg_rx_fifo 
rgb_rx_fifo_inst (
    .rst(hdmi_pixel_rst), // input rst
  
    .wr_clk(hdmi_pixel_clk), // input wr_clk
    .rd_clk(ddr_clk), // input rd_clk

    .din(fifo_data_in), // input [23 : 0] din
    .wr_en(fifo_write_enable), // input wr_en
  
    .rd_en(fifo_read_enable), // input rd_en
    .dout(fifo_data_out), // output [23 : 0] dout
  
    .full(fifo_full), // output full
    .empty(fifo_empty), // output empty

    .overflow(fifo_overflow), // output overflow
    .underflow(fifo_underflow), // output underflow

    .rd_data_count(fifo_wr_data_count), // output [9 : 0] rd_data_count
    .wr_data_count(fifo_rd_data_count) // output [9 : 0] wr_data_count
);

/*
rgb_to_ddr# (
    .RGB_WIDTH(RGB_WIDTH),
    .DATA_COUNT_WIDTH(DATA_COUNT_WIDTH)
)
rgb_to_ddr_inst (
    .clk(ddr_clk),
    .rst(ddr_rst),

    .fifo_data_out(fifo_data_out),
    .fifo_read_enable(fifo_read_enable),
    .fifo_wr_data_count(fifo_wr_data_count),
    .fifo_rd_data_count(fifo_rd_data_count),
    .fifo_full(fifo_full),
    .fifo_empty(fifo_empty)
);
*/

endmodule 
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

module uart_control_fifo# (
    parameter FIFO_DEPTH = 64
)
(
    input wire clk,
    input wire rst,
    
    input  wire uart_rxd,
    output wire uart_txd,
    
    output wire start_write_frame
);


uart_control
uart_control_inst
(
    .clk(clk),
    .rst(rst),

    .rx_fifo_data(rx_fifo_data),
    .rx_fifo_read_enable(rx_fifo_read_enable),
    .rx_fifo_full(rx_fifo_full),
    .rx_fifo_empty(rx_fifo_empty),
    .rx_fifo_data_count(rx_fifo_data_count),

    .start_write_frame(start_write_frame)
);

wire [30:0] uart_setup = 31'h00043D;

wire        tx_uart_busy;
wire [7:0]  tx_uart_data;
wire        tx_uart_valid;

wire [7:0]  rx_uart_data;
wire        rx_uart_valid;

wire [7:0]  rx_fifo_data;
wire        rx_fifo_read_enable;
wire        rx_fifo_full;
wire        rx_fifo_empty;
wire [5:0]  rx_fifo_data_count;
 
rxuart# (
    .INITIAL_SETUP(31'h00043D)
)
rxuart_inst
(
    .i_clk          (clk),
    .i_reset        (rst),
    .i_setup        (uart_setup),
    .i_uart_rx      (uart_rxd),
    .o_wr           (rx_uart_valid),
    .o_data         (rx_uart_data),
    .o_break        (),
    .o_parity_err   (),
    .o_frame_err    (),
    .o_ck_uart      ()
);

txuart# (
    .INITIAL_SETUP(31'h00043D)
)
txuart_inst
(
    .i_clk          (clk),
    .i_reset        (rst),
    .i_setup        (uart_setup),
    .i_break        (),
    .i_wr           (tx_uart_valid),
    .i_data         (tx_uart_data),
    .i_cts_n        (1'b1),
    .o_uart_tx      (uart_txd),
    .o_busy         (tx_uart_busy)
);

uart_rx_fifo
uart_rx_fifo_inst
(
    .clk(clk), // input clk
    .rst(rst), // input rst
    .din(rx_uart_data), // input [7 : 0] din
    .wr_en(rx_uart_valid), // input wr_en
    .rd_en(rx_fifo_read_enable), // input rd_en
    .dout(rx_fifo_data), // output [7 : 0] dout
    .full(rx_fifo_full), // output full
    .overflow(), // output overflow
    .empty(rx_fifo_empty), // output empty
    .underflow(), // output underflow
    .data_count(rx_fifo_data_count) // output [5 : 0] data_count

);


endmodule



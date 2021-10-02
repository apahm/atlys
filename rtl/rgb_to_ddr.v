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

module rgb_to_ddr# (
    parameter RGB_WIDTH = 24,
    parameter DATA_COUNT_WIDTH = 11,
    parameter PIXEL_COUNT  = 4096
)
(
    input wire                                      clk,
    input wire                                      rst,

    input wire                                      c3_calib_done,

    output	wire    	                            c3_p0_cmd_en,
    output  wire    [2:0]	                        c3_p0_cmd_instr,
    output  wire    [5:0]	                        c3_p0_cmd_bl,
    output  wire    [29:0]	                        c3_p0_cmd_byte_addr,
    input   wire    		                        c3_p0_cmd_empty,
    input   wire    		                        c3_p0_cmd_full,

    output	wire    	                            c3_p0_wr_en,
    output  wire    [3:0]	                        c3_p0_wr_mask,
    output  wire    [31:0]	                        c3_p0_wr_data,
    input   wire    		                        c3_p0_wr_full,
    input   wire    		                        c3_p0_wr_empty,
    input   wire    [6:0]	                        c3_p0_wr_count,
    input   wire    		                        c3_p0_wr_underrun,
    input   wire    		                        c3_p0_wr_error,

    input   wire    [RGB_WIDTH - 1:0]               fifo_data_out,
    output  wire                                    fifo_read_enable,
    input   wire    [DATA_COUNT_WIDTH -1:0]         fifo_wr_data_count,
    input   wire    [DATA_COUNT_WIDTH -1:0]         fifo_rd_data_count,
    input   wire                                    fifo_full,
    input   wire                                    fifo_empty,

    output  wire    [7:0]                           led 
);

localparam [5:0] MAX_BURST_LENGHT = 'd63;

localparam [3:0] COMMAND_FIFO_DEPTH = 'd4;

localparam [15:0] BURST_COUNT_FRAME = PIXEL_COUNT/64;

localparam [3:0]
    STATE_WAIT_CALIB = 4'd0,
    STATE_WAIT_RGB_DATA = 4'd1,
    STATE_WRITE = 4'd2,
    STATE_WRITE_COMMAND = 4'd3,
    STATE_ONE_FRAME_SUCCESSFUL = 'd4;

localparam [2:0] 
    WRITE = 3'b0,
    WRITE_AUTO_PRECHARGE = 3'b10;

reg [3:0] state_reg;

reg         p0_cmd_en_reg;
reg [2:0]	p0_cmd_instr_reg;
reg [5:0]	p0_cmd_bl_reg;
reg [29:0]	p0_cmd_byte_addr_reg;

reg 	    p0_wr_en_reg;
reg [3:0]	p0_wr_mask_reg;
reg [31:0]	p0_wr_data_reg;


reg [29:0]  addr_ptr_reg;
reg [6:0]   word_count_reg;
reg [31:0]  error_count_reg;
reg [8:0]   address_iter_reg;
reg [7:0]   led_reg;
reg [15:0]  burst_count_reg;
reg         fifo_rd_enable_reg;

assign fifo_read_enable = fifo_rd_enable_reg;

assign c3_p0_wr_en = p0_wr_en_reg;
assign c3_p0_wr_mask = p0_wr_mask_reg;
assign c3_p0_wr_data = p0_wr_data_reg;

assign c3_p0_cmd_en = p0_cmd_en_reg;
assign c3_p0_cmd_instr = p0_cmd_instr_reg;
assign c3_p0_cmd_bl = p0_cmd_bl_reg;
assign c3_p0_cmd_byte_addr = p0_cmd_byte_addr_reg;

always @(posedge clk) begin
	if (rst) begin
        state_reg <= STATE_WAIT_CALIB;

        p0_cmd_en_reg <= 1'b0;
        p0_cmd_instr_reg <= 3'b0;
        p0_cmd_bl_reg <= 6'b0;
        p0_cmd_byte_addr_reg <= 30'b0;

        p0_wr_en_reg <= 1'b0;
        p0_wr_mask_reg <= 4'b0;
        p0_wr_data_reg <= 32'b0;

        addr_ptr_reg <= 30'b0;
        word_count_reg <= 6'b0;
        address_iter_reg <= 9'hFC;
        led_reg <= 8'b0;
        burst_count_reg <= 'b0;
        fifo_rd_enable_reg <= 'b0;
	end else begin
		case (state_reg)
			STATE_WAIT_CALIB: begin
                if(c3_calib_done)
                    state_reg <= STATE_WAIT_RGB_DATA;
                else
                    state_reg <= STATE_WAIT_CALIB;
			end
            STATE_WAIT_RGB_DATA: begin
                p0_cmd_en_reg <= 1'b0;
                if(burst_count_reg == BURST_COUNT_FRAME) begin
                    state_reg <= STATE_ONE_FRAME_SUCCESSFUL;
                end else begin
                    if(fifo_wr_data_count == 'd64 || fifo_wr_data_count > 'd64)
                        state_reg <= STATE_WRITE;
                    else
                        state_reg <= STATE_WAIT_RGB_DATA;
                end
            end
            STATE_WRITE: begin
                if(word_count_reg == 'd64) begin
                    state_reg <= STATE_WRITE_COMMAND;

                    p0_wr_en_reg <= 1'b0; 
                    word_count_reg <= 6'b0;
                    fifo_rd_enable_reg <= 'b0;
                    burst_count_reg <= burst_count_reg + 1'b1;
                end else begin
                    fifo_rd_enable_reg <= 'b1;

                    p0_wr_en_reg <= 1'b1;
                    p0_wr_mask_reg <= 4'b0;
                    p0_wr_data_reg <= fifo_data_out;

                    word_count_reg <= word_count_reg + 1'b1;
                    state_reg <= STATE_WRITE;
                end
            end
			STATE_WRITE_COMMAND: begin
                if(!c3_p0_cmd_full) begin
                    p0_cmd_en_reg <= 1'b1;
                    p0_cmd_instr_reg <= WRITE_AUTO_PRECHARGE;
                    p0_cmd_bl_reg <= MAX_BURST_LENGHT;
                    p0_cmd_byte_addr_reg <= addr_ptr_reg;

                    addr_ptr_reg <= addr_ptr_reg + {address_iter_reg,2'b0};

                    state_reg <= STATE_WAIT_RGB_DATA;
                end else begin
                    state_reg <= STATE_WRITE_COMMAND;
                end
			end
            STATE_ONE_FRAME_SUCCESSFUL: begin
                state_reg <= STATE_ONE_FRAME_SUCCESSFUL;
                burst_count_reg <= 'b0;
            end
		endcase
	end
end

endmodule
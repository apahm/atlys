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

module ddr_ctrl #(

)
(
    input wire                  clk,
    input wire                  rst,

    input wire                  c3_calib_done,

    output	wire    	        c3_p0_cmd_en,
    output  wire    [2:0]	    c3_p0_cmd_instr,
    output  wire    [5:0]	    c3_p0_cmd_bl,
    output  wire    [29:0]	    c3_p0_cmd_byte_addr,
    input   wire    		    c3_p0_cmd_empty,
    input   wire    		    c3_p0_cmd_full,

    output	wire    	        c3_p0_wr_en,
    output  wire    [3:0]	    c3_p0_wr_mask,
    output  wire    [31:0]	    c3_p0_wr_data,
    input   wire    		    c3_p0_wr_full,
    input   wire    		    c3_p0_wr_empty,
    input   wire    [6:0]	    c3_p0_wr_count,
    input   wire    		    c3_p0_wr_underrun,
    input   wire    		    c3_p0_wr_error,
    
    output	wire    	        c3_p0_rd_en,
    input   wire     [31:0]	    c3_p0_rd_data,
    input   wire    		    c3_p0_rd_full,
    input   wire    		    c3_p0_rd_empty,
    input   wire     [6:0]	    c3_p0_rd_count,
    input   wire    		    c3_p0_rd_overflow,
    input   wire    		    c3_p0_rd_error,
    
    output	wire    	        c3_p2_cmd_en,
    output  wire    [2:0]	    c3_p2_cmd_instr,
    output  wire    [5:0]	    c3_p2_cmd_bl,
    output  wire    [29:0]	    c3_p2_cmd_byte_addr,
    input   wire    		    c3_p2_cmd_empty,
    input   wire    		    c3_p2_cmd_full,
    
    output	wire    	        c3_p2_rd_en,
    input   wire     [31:0]	    c3_p2_rd_data,
    input   wire    		    c3_p2_rd_full,
    input   wire    		    c3_p2_rd_empty,
    input   wire     [6:0]	    c3_p2_rd_count,
    input   wire    		    c3_p2_rd_overflow,
    input   wire    		    c3_p2_rd_error,

    output  wire     [7:0]      led 
);

localparam [5:0] MAX_BURST_LENGHT = 6'd63;

localparam [3:0] COMMAND_FIFO_DEPTH = 3'd4;
localparam [3:0] WRITE_READ_FIFO_DEPTH = 7'64;

localparam [3:0]
    STATE_WAIT_CALIB = 4'd0,
    STATE_WRITE_COMMAND = 4'd1,
    STATE_WAIT_FIFO_EMPTY = 4'd2,
    STATE_WRITE = 4'd3,
    STATE_READ_COMMAND = 4'd4,
    STATE_WAIT_FIFO_FULL = 4'd5,
    STATE_READ = 4'd6,
    STATE_COMPARE = 4'd7,
    STATE_TEST_SUCCESSFUL = 4'd8;

localparam [2:0] 
    WRITE = 3'b0,
    READ = 3'b1,
    WRITE_AUTO_PRECHARGE = 3'b10,
    READ_AUTO_PRECHRGE = 3'b11,
    REFRESH = 3'b100;


reg [2:0] state_reg;

reg         p0_cmd_en_reg;
reg [2:0]	p0_cmd_instr_reg;
reg [5:0]	p0_cmd_bl_reg;
reg [29:0]	p0_cmd_byte_addr_reg;

reg 	    p0_wr_en_reg;
reg [3:0]	p0_wr_mask_reg;
reg [31:0]	p0_wr_data_reg;

reg         p0_rd_en_reg;

reg         p2_cmd_en_reg;
reg [2:0]	p2_cmd_instr_reg;
reg [5:0]	p2_cmd_bl_reg;
reg [29:0]	p2_cmd_byte_addr_reg;

reg         p2_rd_en_reg;

// Test regs
reg [29:0] addr_ptr_reg;
reg [5:0]  word_count_reg;
reg [31:0] error_count_reg;
reg [8:0] address_iter_reg;
reg [7:0] led_reg;

// Test memory reg
reg [31:0] memory_reg [0:63];
reg [31:0] memory_read_reg [0:63];

assign led = led_reg;

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

        p0_rd_en_reg <= 1'b0;

        addr_ptr_reg <= 30'b0;
        word_count_reg <= 6'b0;
        address_iter_reg <= 9'hFC;
        error_count_reg <= 32'b0;
        led_reg <= 8'b0;
	end else begin
		case (state_reg)
			STATE_WAIT_CALIB: begin
                if(c3_calib_done)
                    state_reg <= STATE_WRITE_COMMAND;
                else
                    state_reg <= STATE_WAIT_CALIB;
			end
			STATE_WRITE_COMMAND: begin
                if(!c3_p0_cmd_full) begin
                    p0_cmd_en_reg <= 1'b1;
                    p0_cmd_instr_reg <= WRITE_AUTO_PRECHARGE;
                    p0_cmd_bl_reg <= MAX_BURST_LENGHT;
                    p0_cmd_byte_addr_reg <= addr_ptr_reg;

                    addr_ptr_reg <= addr_ptr_reg + 30'hFC;
 
                    state_reg <= STATE_WRITE;
                end else begin
                    state_reg <= STATE_WRITE_COMMAND;
                end
			end
			STATE_WAIT_FIFO_EMPTY: begin
                if(c3_p0_wr_empty) begin
                    state_reg <= STATE_WRITE;
                end else begin
                    state_reg <= STATE_WAIT_FIFO_EMPTY;
                end 
			end
            STATE_WRITE: begin
                if(word_count_reg == 6'd63)
                    state_reg <= STATE_WRITE_COMMAND;
                    word_count_reg <= 6'b0;
                end else begin
                    p0_wr_en_reg <= 1'b1;
                    p0_wr_mask_reg <= 4'b0;
                    p0_wr_data_reg <= memory_reg[word_count_reg];
                    word_count_reg <= word_count_reg + 1'b1;
                    state_reg <= STATE_WRITE;
                end
            end
            STATE_WRITE: begin
                if(word_count_reg == 6'd63)
                    state_reg <= STATE_WRITE_COMMAND;
                    p0_wr_en_reg <= 1'b0; 
                    word_count_reg <= 6'b0;
                end else begin
                    p0_wr_en_reg <= 1'b1;
                    p0_wr_mask_reg <= 4'b0;
                    p0_wr_data_reg <= memory_reg[word_count_reg];
                    word_count_reg <= word_count_reg + 1'b1;
                    state_reg <= STATE_WRITE;
                end
            end
            STATE_READ_COMMAND: begin
                if(!c3_p0_cmd_full) begin
                    p0_cmd_en_reg <= 1'b1;
                    p0_cmd_instr_reg <= READ_AUTO_PRECHRGE;
                    p0_cmd_bl_reg <= MAX_BURST_LENGHT;
                    p0_cmd_byte_addr_reg <= addr_ptr_reg;

                    addr_ptr_reg <= addr_ptr_reg + 30'hFC;
 
                    state_reg <= STATE_READ;
                end else begin
                    state_reg <= STATE_READ_COMMAND;
                end
            end
            STATE_WAIT_FIFO_FULL: begin
                if(c3_p0_rd_full) begin
                    state_reg <= STATE_READ;
                end else begin
                    state_reg <= STATE_WAIT_FIFO_FULL;
                end 
            end
            STATE_READ: begin
                if(word_count_reg == 6'd63)
                    state_reg <= STATE_COMPARE;
                    word_count_reg <= 6'b0;
                    p0_rd_en_reg <= 1'b0;
                end else begin
                    p0_rd_en_reg <= 1'b1;
                    memory_read_reg[word_count_reg] <= c3_p0_rd_data;
                    word_count_reg <= word_count_reg + 1'b1;
                    state_reg <= STATE_READ;
                end
            end
            STATE_COMPARE: begin
                if(word_count_reg == 6'd63)
                    state_reg <= STATE_READ_COMMAND;
                    word_count_reg <= 6'b0;
                end else begin
                    if(memory_read_reg[word_count_reg] != memory_reg[word_count_reg]) begin
                        error_count_reg <= error_count_reg + 1'b1;
                    end
                    word_count_reg <= word_count_reg + 1'b1;
                    state_reg <= STATE_COMPARE;
                end
            end
            STATE_TEST_SUCCESSFUL: begin
                led_reg <= error_count_reg;
            end
		endcase
	end
end


endmodule 
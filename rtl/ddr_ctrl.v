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
    input   wire    		    c3_p2_rd_error
);

localparam [5:0] MAX_BURST_LENGHT = 6'd64;

localparam [2:0]
    STATE_WAIT_CALIB = 3'd0,
    STATE_WRITE_COMMAND = 3'd1,
    STATE_WRITE = 3'd2;

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
                    p0_cmd_instr_reg <= WRITE;
                    p0_cmd_bl_reg <= 6'b0;
                    p0_cmd_byte_addr_reg <= 30'b0;

                    state_reg <= STATE_WRITE;
                end else begin
                    state_reg <= STATE_WRITE_COMMAND;
                end
			end
			STATE_WRITE: begin
                
			end

			INIT_PGM_MODE: begin

			end
		endcase
	end
end


endmodule 
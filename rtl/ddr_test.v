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

module ddr_test
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
localparam [3:0] WRITE_READ_FIFO_DEPTH = 7'd64;

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
reg [6:0]  word_count_reg;
reg [31:0] error_count_reg;
reg [8:0] address_iter_reg;
reg [7:0] led_reg;
// Test memory reg
reg [31:0] memory_reg [0:63];
reg [31:0] memory_read_reg [0:63];

assign led = c3_p0_wr_count;

assign c3_p0_rd_en = p0_rd_en_reg;

assign c3_p0_wr_en = p0_wr_en_reg;
assign c3_p0_wr_mask = p0_wr_mask_reg;
assign c3_p0_wr_data = p0_wr_data_reg;

assign c3_p0_cmd_en = (p0_cmd_en_reg);
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
                    state_reg <= STATE_WAIT_FIFO_EMPTY;
                end else begin
                    state_reg <= STATE_WRITE_COMMAND;
                end
			end
			STATE_WAIT_FIFO_EMPTY: begin
                p0_cmd_en_reg <= 1'b0;
                if(c3_p0_wr_empty) begin
                    state_reg <= STATE_WRITE;
                end else begin
                    state_reg <= STATE_WAIT_FIFO_EMPTY;
                end 
			end
            STATE_WRITE: begin
                if(word_count_reg == 'd64) begin
                    state_reg <= STATE_TEST_SUCCESSFUL;
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
                if(word_count_reg == 6'd63) begin
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
                if(word_count_reg == 6'd63) begin
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
                state_reg <= STATE_TEST_SUCCESSFUL;
            end
		endcase
	end
end

always @(posedge clk) begin
    if(rst) begin
        memory_reg[0]  <= 32'h12345678;
        memory_reg[1]  <= 32'h87654321;
        memory_reg[2]  <= 32'h12121212;
        memory_reg[3]  <= 32'h8A4FBCD1;
        memory_reg[4]  <= 32'h92374DAB;
        memory_reg[5]  <= 32'h15964278;
        memory_reg[6]  <= 32'hABCD1235;
        memory_reg[7]  <= 32'h78945612;
        memory_reg[8]  <= 32'h36952147;
        memory_reg[9]  <= 32'hABCD9623;
        memory_reg[10] <= 32'h32123423;
        memory_reg[11] <= 32'h65423432;
        memory_reg[12] <= 32'hB2343255;
        memory_reg[13] <= 32'hA2321543;
        memory_reg[14] <= 32'hBC965217;
        memory_reg[15] <= 32'hAC598413;
        memory_reg[16] <= 32'h56446ACD;
        memory_reg[17] <= 32'h95123489;
        memory_reg[18] <= 32'hFF2844FF;
        memory_reg[19] <= 32'hABCDEFFF;
        memory_reg[20] <= 32'h123FFACB;
        memory_reg[21] <= 32'h78945612;
        memory_reg[22] <= 32'h321ABCDE;
        memory_reg[23] <= 32'h12FFFFFF;
        memory_reg[24] <= 32'h12359FAB;
        memory_reg[25] <= 32'h1432FDAC;
        memory_reg[26] <= 32'h123ACDFF;
        memory_reg[27] <= 32'hEEEFFFAA;
        memory_reg[28] <= 32'hBBCCAAFF;
        memory_reg[29] <= 32'h11223344;
        memory_reg[30] <= 32'h55667788;
        memory_reg[31] <= 32'h12345678;
        memory_reg[32] <= 32'h12345678;
        memory_reg[33] <= 32'h87654321;
        memory_reg[34] <= 32'h12121212;
        memory_reg[35] <= 32'h8A4FBCD1;
        memory_reg[36] <= 32'h92374DAB;
        memory_reg[37] <= 32'h15964278;
        memory_reg[38] <= 32'hABCD1235;
        memory_reg[39] <= 32'h78945612;
        memory_reg[40] <= 32'h36952147;
        memory_reg[41] <= 32'hABCD9623;
        memory_reg[42] <= 32'h32123423;
        memory_reg[43] <= 32'h65423432;
        memory_reg[44] <= 32'hB2343255;
        memory_reg[45] <= 32'hA2321543;
        memory_reg[46] <= 32'hBC965217;
        memory_reg[47] <= 32'hAC598413;
        memory_reg[48] <= 32'h56446ACD;
        memory_reg[49] <= 32'h95123489;
        memory_reg[50] <= 32'hFF2844FF;
        memory_reg[51] <= 32'hABCDEFFF;
        memory_reg[52] <= 32'h123FFACB;
        memory_reg[53] <= 32'h78945612;
        memory_reg[54] <= 32'h321ABCDE;
        memory_reg[55] <= 32'h12FFFFFF;
        memory_reg[56] <= 32'h12359FAB;
        memory_reg[57] <= 32'h1432FDAC;
        memory_reg[58] <= 32'h123ACDFF;
        memory_reg[59] <= 32'hEEEFFFAA;
        memory_reg[60] <= 32'hBBCCAAFF;
        memory_reg[61] <= 32'h11223344;
        memory_reg[62] <= 32'h55667788;
        memory_reg[63] <= 32'h99AABBCC;
    end
end

endmodule 
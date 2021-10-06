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
    input   wire rst,          // rx reset
    input   wire clk,           // regenerated pixel clock

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
    output  wire          fifo_write_enable,

    input   wire          start_write  
      
);

localparam [3:0]
    STATE_WAIT_COMMAND_START = 4'd0,
    STATE_WAIT_HDMI_READY = 4'd1,
    STATE_WAIT_BEGIN_FRAME = 4'd2,
    STATE_WAIT_VSYNC = 4'd4,
    STATE_WAIT_HSYNC = 4'd5,
    STATE_WAIT_DATA_EN = 4'd6;

reg [3:0] state_reg;

reg de_reg;
reg vsync_reg;
reg hsync_reg;

reg         fifo_write_enable_reg;
reg [15:0]  fifo_data_counter_reg;
reg [15:0]  row_count_reg;
wire hdmi_ready;

assign fifo_data_in = {red, green, blue};
assign hdmi_ready = blue_rdy && green_rdy && red_rdy && blue_vld && green_vld && red_vld;

always @(posedge clk) begin
    if(rst) begin
        de_reg <= 1'b0;
        vsync_reg <= 1'b0;
        hsync_reg <= 1'b0;
    end else begin
        de_reg <= de;
        vsync_reg <= vsync;
        hsync_reg <= hsync;
    end
end

always @(posedge clk) begin
	if (rst) begin
        state_reg <= STATE_WAIT_HDMI_READY;
        fifo_write_enable_reg <= 1'b0;
        fifo_data_counter_reg <= 'b0;
        row_count_reg <= 'b0;
	end else begin
		case (state_reg)
            STATE_WAIT_COMMAND_START: begin
                if(start_write)
                    state_reg <= STATE_WAIT_HDMI_READY;
                else
                    state_reg <= STATE_WAIT_COMMAND_START;
            end
			STATE_WAIT_HDMI_READY: begin
                if(hdmi_ready)
                    state_reg <= STATE_WAIT_BEGIN_FRAME;
                else
                    state_reg <= STATE_WAIT_HDMI_READY;
			end
            STATE_WAIT_BEGIN_FRAME: begin
                if(de == 1'b1 && vsync == 1'b0) begin
                    state_reg <= STATE_WAIT_VSYNC;
                end else
                    state_reg <= STATE_WAIT_BEGIN_FRAME;
            end
            STATE_WAIT_VSYNC: begin
                if(vsync_reg == 1'b0 && vsync == 1'b1) begin
                    state_reg <= STATE_WAIT_DATA_EN;
                end else 
                    state_reg <= STATE_WAIT_VSYNC;
            end
            STATE_WAIT_HSYNC: begin
                if(hsync == 1'b0 && hsync_reg == 1'b1) begin
                    state_reg <= STATE_WAIT_DATA_EN;
                end else
                    state_reg <= STATE_WAIT_HSYNC;
            end
            STATE_WAIT_DATA_EN: begin
                if(row_count_reg == 'd63) begin
                    state_reg <= STATE_WAIT_BEGIN_FRAME;
                end else begin
                    if(fifo_data_counter_reg == 'd63) begin
                        fifo_write_enable_reg <= 1'b0;
                        fifo_data_counter_reg <= 'b0;
                        row_count_reg <= row_count_reg + 1'b1;
                        state_reg <= STATE_WAIT_HSYNC;
                    end else begin
                        fifo_write_enable_reg <= de;

                        if(vsync == 1'b1 && de == 1'b1) begin
                            fifo_data_counter_reg <= fifo_data_counter_reg + 1'b1;
                        end else 
                            state_reg <= STATE_WAIT_DATA_EN;
                    end
                end
            end
		endcase
	end
end
endmodule
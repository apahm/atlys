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

module eth_pack_fifo
(
    input  wire        ddr_clk,
    input  wire        ddr_rst,
    
    input  wire        eth_clk,
    input  wire        eth_rst,

    input  wire [7:0]  s_frame_axis_tdata,
    input  wire        s_frame_axis_tvalid,
    output wire        s_frame_axis_tready,
    /*
     * Ethernet frame output
     */
    output wire        m_eth_hdr_valid,
    input  wire        m_eth_hdr_ready,
    output wire [47:0] m_eth_dest_mac,
    output wire [47:0] m_eth_src_mac,
    output wire [15:0] m_eth_type,
    output wire [7:0]  m_eth_payload_axis_tdata,
    output wire        m_eth_payload_axis_tvalid,
    input  wire        m_eth_payload_axis_tready,
    output wire        m_eth_payload_axis_tlast,
    output wire        m_eth_payload_axis_tuser
);

wire        fifo_m_axis_tvalid;
wire        fifo_m_axis_tready;
wire [8:0]  fifo_m_axis_tdata;
wire [10:0] fifo_axis_wr_data_count;
wire [10:0] fifo_axis_rd_data_count;
wire        fifo_axis_overflow;
wire        fifo_axis_underflow;


eth_tx_fifo 
eth_tx_fifo_inst (
    .m_aclk(eth_clk), // input m_aclk
    .s_aclk(ddr_clk), // input s_aclk
    .s_aresetn(~ddr_rst), // input s_aresetn

    .s_axis_tvalid(s_frame_axis_tvalid), // input s_axis_tvalid
    .s_axis_tready(s_frame_axis_tready), // output s_axis_tready
    .s_axis_tdata(s_frame_axis_tdata), // input [7 : 0] s_axis_tdata

    .m_axis_tvalid(fifo_m_axis_tvalid), // output m_axis_tvalid
    .m_axis_tready(fifo_m_axis_tready), // input m_axis_tready
    .m_axis_tdata(fifo_m_axis_tdata), // output [7 : 0] m_axis_tdata

    .axis_wr_data_count(fifo_axis_wr_data_count), // output [10 : 0] axis_wr_data_count
    .axis_rd_data_count(fifo_axis_rd_data_count), // output [10 : 0] axis_rd_data_count
  
    .axis_overflow(fifo_axis_overflow), // output axis_overflow
    .axis_underflow(fifo_axis_underflow) // output axis_underflow
);


eth_pack
eth_pack_inst (
    .clk(eth_clk),
    .rst(eth_rst),

    .s_fifo_axis_tdata(fifo_m_axis_tdata),
    .s_fifo_axis_tvalid(fifo_m_axis_tvalid),
    .s_fifo_axis_tready(fifo_m_axis_tready),
    .s_fifo_wr_data_count(fifo_axis_wr_data_count),
    .s_fifo_rd_data_count(fifo_axis_rd_data_count),
    /*
     * Ethernet frame output
     */
    .m_eth_hdr_valid(m_eth_hdr_valid),
    .m_eth_hdr_ready(m_eth_hdr_ready),
    .m_eth_dest_mac(m_eth_dest_mac),
    .m_eth_src_mac(m_eth_src_mac),
    .m_eth_type(m_eth_type),
    .m_eth_payload_axis_tdata(m_eth_payload_axis_tdata),
    .m_eth_payload_axis_tvalid(m_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(m_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(m_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(m_eth_payload_axis_tuser)
);

endmodule 
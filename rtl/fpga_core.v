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

/*
 * FPGA core logic
 */
module fpga_core #
(
    parameter TARGET = "GENERIC",
    parameter MIG_SIM = "TRUE"
)
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire                                         clk,
    input  wire                                         rst,

    /*
     * Clock: 125 MHz
     * DDR2: MIRA P3R1GE3EGF G8E DDR2 
     */
    input   wire                                        ddr_clk,
    input   wire                                        ddr_rst,
    inout   wire     [15:0]                             ddr_dq,
    output  wire     [12:0]                             ddr_a,
    output  wire     [2:0]                              ddr_ba,
    output  wire                                        ddr_ras_n,
    output  wire                                        ddr_cas_n,
    output  wire                                        ddr_we_n,
    output  wire                                        ddr_odt,
    output  wire                                        ddr_cke,
    output  wire                                        ddr_dm,
    inout   wire                                        ddr_udqs,
    inout   wire                                        ddr_udqs_n,
    inout   wire                                        ddr_dqs,
    inout   wire                                        ddr_dqs_n,
    output  wire                                        ddr_ck,
    output  wire                                        ddr_ck_n,
    output  wire                                        ddr_udm,

    /*
     * GPIO
     */
    output wire     [7:0]                               led,

    /*
     * Ethernet: 1000BASE-T GMII
     */
    input  wire                                         phy_rx_clk,
    input  wire     [7:0]                               phy_rxd,
    input  wire                                         phy_rx_dv,
    input  wire                                         phy_rx_er,
    output wire                                         phy_gtx_clk,
    input  wire                                         phy_tx_clk,
    output wire     [7:0]                               phy_txd,
    output wire                                         phy_tx_en,
    output wire                                         phy_tx_er,
    output wire                                         phy_reset_n,

    /*
     * UART: 115200 bps, 8N1
     */
    input  wire                                         uart_rxd,
    output wire                                         uart_txd,

    input   wire                                        hdmi_rx_clk_p,      
    input   wire                                        hdmi_rx_clk_n,      
    input   wire    [2:0]                               hdmi_rx_p,
    input   wire    [2:0]                               hdmi_rx_n
    
);
`define LED_DEBUG_HDMI
/* 
*   Module DDR2 Controller
*/
wire				                c3_p0_cmd_clk;
wire				                c3_p0_cmd_en;
wire    [2:0]			            c3_p0_cmd_instr;
wire    [5:0]			            c3_p0_cmd_bl;
wire    [29:0]			            c3_p0_cmd_byte_addr;
wire				                c3_p0_cmd_empty;
wire				                c3_p0_cmd_full;

wire				                c3_p0_wr_clk;
wire				                c3_p0_wr_en;
wire    [3:0]	                    c3_p0_wr_mask;
wire    [31:0]	                    c3_p0_wr_data;
wire				                c3_p0_wr_full;
wire				                c3_p0_wr_empty;
wire	[6:0]		                c3_p0_wr_count;
wire				                c3_p0_wr_underrun;
wire				                c3_p0_wr_error;

wire				                c3_p0_rd_clk;
wire				                c3_p0_rd_en;
wire    [31:0]	                    c3_p0_rd_data;
wire				                c3_p0_rd_full;
wire				                c3_p0_rd_empty;
wire    [6:0]			            c3_p0_rd_count;
wire				                c3_p0_rd_overflow;
wire				                c3_p0_rd_error;

wire				                c3_p2_cmd_clk;
wire				                c3_p2_cmd_en;
wire    [2:0]			            c3_p2_cmd_instr;
wire    [5:0]			            c3_p2_cmd_bl;
wire    [29:0]			            c3_p2_cmd_byte_addr;
wire				                c3_p2_cmd_empty;
wire				                c3_p2_cmd_full;

wire				                c3_p2_rd_clk;
wire				                c3_p2_rd_en;
wire    [31:0]			            c3_p2_rd_data;
wire				                c3_p2_rd_full;
wire				                c3_p2_rd_empty;
wire    [6:0]			            c3_p2_rd_count;
wire				                c3_p2_rd_overflow;
wire				                c3_p2_rd_error;

wire c3_clk0;
wire c3_rst0;
wire c3_calib_done;

wire ddr_rzq;
wire ddr_zio;

wire s_frame_axis_tready;

/* 
*   LED Debug
*/
`ifdef LED_DEBUG

    assign led[0] = c3_calib_done;
    assign led[1] = c3_rst0;
    assign led[2] = s_frame_axis_tready;
    assign led[3] = hdmi_green_vld;
    assign led[4] = hdmi_red_vld;
    assign led[5] = hdmi_blue_rdy;
    assign led[6] = hdmi_green_rdy;
    assign led[7] = hdmi_red_rdy;

`endif

`ifdef LED_DEBUG_HDMI

    assign led[0] = hdmi_de;
    assign led[1] = hdmi_vsync;
    assign led[2] = hdmi_hsync;
    assign led[3] = hdmi_green_vld;
    assign led[4] = hdmi_red_vld;
    assign led[5] = hdmi_blue_rdy;
    assign led[6] = hdmi_green_rdy;
    assign led[7] = hdmi_red_rdy;

`endif

ddr2_controller# (
    .C3_P0_MASK_SIZE(4),
    .C3_P0_DATA_PORT_SIZE(32),
    .C3_P1_MASK_SIZE(4),
    .C3_P1_DATA_PORT_SIZE(32),
    .DEBUG_EN(0),
    .C3_MEMCLK_PERIOD(8000),
    .C3_CALIB_SOFT_IP("TRUE"),
    .C3_SIMULATION(MIG_SIM),
    .C3_RST_ACT_LOW(0),
    .C3_INPUT_CLK_TYPE("SINGLE_ENDED"),
    .C3_MEM_ADDR_ORDER("ROW_BANK_COLUMN"),
    .C3_NUM_DQ_PINS(16),
    .C3_MEM_ADDR_WIDTH(13),
    .C3_MEM_BANKADDR_WIDTH(3)
)
ddr2_controller_inst 
(

    .c3_sys_clk             (ddr_clk),
    .c3_sys_rst_i           (ddr_rst),                        

    .mcb3_dram_dq           (ddr_dq),  
    .mcb3_dram_a            (ddr_a),  
    .mcb3_dram_ba           (ddr_ba),
    .mcb3_dram_ras_n        (ddr_ras_n),                        
    .mcb3_dram_cas_n        (ddr_cas_n),                        
    .mcb3_dram_we_n         (ddr_we_n),                          
    .mcb3_dram_odt          (ddr_odt),
    .mcb3_dram_cke          (ddr_cke),                          
    .mcb3_dram_ck           (ddr_ck),                          
    .mcb3_dram_ck_n         (ddr_ck_n),       
    .mcb3_dram_dqs          (ddr_dqs),
    .mcb3_dram_dqs_n        (ddr_dqs_n),                          
    .mcb3_dram_udqs         (ddr_udqs),
    .mcb3_dram_udqs_n       (ddr_udqs_n),                        
    .mcb3_dram_udm          (ddr_udm),     
    .mcb3_dram_dm           (ddr_dm),
    .c3_clk0		        (c3_clk0),
    .c3_rst0		        (c3_rst0),
	
 
    .c3_calib_done          (c3_calib_done),
    .mcb3_rzq               (ddr_rzq),
               

    // config_port_0             
    .c3_p0_cmd_clk                          (c3_clk0),
    .c3_p0_cmd_en                           (c3_p0_cmd_en),
    .c3_p0_cmd_instr                        (c3_p0_cmd_instr),
    .c3_p0_cmd_bl                           (c3_p0_cmd_bl),
    .c3_p0_cmd_byte_addr                    (c3_p0_cmd_byte_addr),
    .c3_p0_cmd_empty                        (c3_p0_cmd_empty),
    .c3_p0_cmd_full                         (c3_p0_cmd_full),

    .c3_p0_wr_clk                           (c3_clk0),
    .c3_p0_wr_en                            (c3_p0_wr_en),
    .c3_p0_wr_mask                          (c3_p0_wr_mask),
    .c3_p0_wr_data                          (c3_p0_wr_data),
    .c3_p0_wr_full                          (c3_p0_wr_full),
    .c3_p0_wr_empty                         (c3_p0_wr_empty),
    .c3_p0_wr_count                         (c3_p0_wr_count),
    .c3_p0_wr_underrun                      (c3_p0_wr_underrun),
    .c3_p0_wr_error                         (c3_p0_wr_error),
    
    .c3_p0_rd_clk                           (c3_clk0),
    .c3_p0_rd_en                            (c3_p0_rd_en),
    .c3_p0_rd_data                          (c3_p0_rd_data),
    .c3_p0_rd_full                          (c3_p0_rd_full),
    .c3_p0_rd_empty                         (c3_p0_rd_empty),
    .c3_p0_rd_count                         (c3_p0_rd_count),
    .c3_p0_rd_overflow                      (c3_p0_rd_overflow),
    .c3_p0_rd_error                         (c3_p0_rd_error),
    
    // config_port_2 
    .c3_p2_cmd_clk                          (c3_clk0),
    .c3_p2_cmd_en                           (c3_p2_cmd_en),
    .c3_p2_cmd_instr                        (c3_p2_cmd_instr),
    .c3_p2_cmd_bl                           (c3_p2_cmd_bl),
    .c3_p2_cmd_byte_addr                    (c3_p2_cmd_byte_addr),
    .c3_p2_cmd_empty                        (c3_p2_cmd_empty),
    .c3_p2_cmd_full                         (c3_p2_cmd_full),
    
    .c3_p2_rd_clk                           (c3_clk0),
    .c3_p2_rd_en                            (c3_p2_rd_en),
    .c3_p2_rd_data                          (c3_p2_rd_data),
    .c3_p2_rd_full                          (c3_p2_rd_full),
    .c3_p2_rd_empty                         (c3_p2_rd_empty),
    .c3_p2_rd_count                         (c3_p2_rd_count),
    .c3_p2_rd_overflow                      (c3_p2_rd_overflow),
    .c3_p2_rd_error                         (c3_p2_rd_error)
);



ddr_test
ddr_test_inst
(
    .clk(c3_clk0),
    .rst(c3_rst0),

    .c3_calib_done(c3_calib_done),

    .c3_p0_cmd_en(c3_p0_cmd_en),
    .c3_p0_cmd_instr(c3_p0_cmd_instr),
    .c3_p0_cmd_bl(c3_p0_cmd_bl),
    .c3_p0_cmd_byte_addr(c3_p0_cmd_byte_addr),
    .c3_p0_cmd_empty(c3_p0_cmd_empty),
    .c3_p0_cmd_full(c3_p0_cmd_full),

    .c3_p0_wr_en(c3_p0_wr_en),
    .c3_p0_wr_mask(c3_p0_wr_mask),
    .c3_p0_wr_data(c3_p0_wr_data),
    .c3_p0_wr_full(c3_p0_wr_full),
    .c3_p0_wr_empty(c3_p0_wr_empty),
    .c3_p0_wr_count(c3_p0_wr_count),
    .c3_p0_wr_underrun(c3_p0_wr_underrun),
    .c3_p0_wr_error(c3_p0_wr_error),

    .c3_p0_rd_en(c3_p0_rd_en),
    .c3_p0_rd_data(c3_p0_rd_data),
    .c3_p0_rd_full(c3_p0_rd_full),
    .c3_p0_rd_empty(c3_p0_rd_empty),
	.c3_p0_rd_count(c3_p0_rd_count),
    .c3_p0_rd_overflow(c3_p0_rd_overflow),
    .c3_p0_rd_error(c3_p0_rd_error),

    .c3_p2_cmd_en(c3_p2_cmd_en),
    .c3_p2_cmd_instr(c3_p2_cmd_instr),
    .c3_p2_cmd_bl(c3_p2_cmd_bl),
    .c3_p2_cmd_byte_addr(c3_p2_cmd_byte_addr),
    .c3_p2_cmd_empty(c3_p2_cmd_empty),
    .c3_p2_cmd_full(c3_p2_cmd_full),

    .c3_p2_rd_en(c3_p2_rd_en),
    .c3_p2_rd_data(c3_p2_rd_data),
    .c3_p2_rd_full(c3_p2_rd_full),
    .c3_p2_rd_empty(c3_p2_rd_empty),
    .c3_p2_rd_count(c3_p2_rd_count),
    .c3_p2_rd_overflow(c3_p2_rd_overflow),
    .c3_p2_rd_error(c3_p2_rd_error)

    
);


/* 
*   Module HDMI
*/

wire hdmi_pixel_clk;
wire hdmi_reset;          
wire hdmi_hsync;         
wire hdmi_vsync;         
wire hdmi_de;            
wire hdmi_blue_vld;
wire hdmi_green_vld;
wire hdmi_red_vld;
wire hdmi_blue_rdy;
wire hdmi_green_rdy;
wire hdmi_red_rdy;
wire [7:0] hdmi_red;    
wire [7:0] hdmi_green;   
wire [7:0] hdmi_blue;  
wire start_write_frame;

hdmi_top 
hdmi_top_inst
(
    .rst                (rst),

    .hdmi_rx_clk_p      (hdmi_rx_clk_p), 
    .hdmi_rx_clk_n      (hdmi_rx_clk_n), 
    .hdmi_rx_p          (hdmi_rx_p),
    .hdmi_rx_n          (hdmi_rx_n),

    .reset              (hdmi_reset),
    .pclk               (hdmi_pixel_clk),

    .hsync              (hdmi_hsync),
    .vsync              (hdmi_vsync),
    .de                 (hdmi_de),

    .blue_vld           (hdmi_blue_vld),
    .green_vld          (hdmi_green_vld),
    .red_vld            (hdmi_red_vld),
    .blue_rdy           (hdmi_blue_rdy),
    .green_rdy          (hdmi_green_rdy),
    .red_rdy            (hdmi_red_rdy),

    .red                (hdmi_red),
    .green              (hdmi_green),
    .blue               (hdmi_blue)
);

/* 
*   Module Uart
*/

uart_control_fifo
uart_control_fifo_inst
(
    .clk(clk),
    .rst(rst),
    
    .uart_rxd(uart_rxd),
    .uart_txd(uart_txd),
    
    .start_write_frame(start_write_frame)
);
/* 
*   Module Ethernet: MAC
*/


// AXI between MAC and Ethernet modules
wire [7:0] rx_axis_tdata;
wire rx_axis_tvalid;
wire rx_axis_tready;
wire rx_axis_tlast;
wire rx_axis_tuser;

wire [7:0] tx_axis_tdata;
wire tx_axis_tvalid;
wire tx_axis_tready;
wire tx_axis_tlast;
wire tx_axis_tuser;


wire rx_eth_hdr_ready;
wire rx_eth_hdr_valid;
wire [47:0] rx_eth_dest_mac;
wire [47:0] rx_eth_src_mac;
wire [15:0] rx_eth_type;
wire [7:0] rx_eth_payload_axis_tdata;
wire rx_eth_payload_axis_tvalid;
wire rx_eth_payload_axis_tready;
wire rx_eth_payload_axis_tlast;
wire rx_eth_payload_axis_tuser;

wire tx_eth_hdr_ready;
wire tx_eth_hdr_valid;
wire [47:0] tx_eth_dest_mac;
wire [47:0] tx_eth_src_mac;
wire [15:0] tx_eth_type;
wire [7:0] tx_eth_payload_axis_tdata;
wire tx_eth_payload_axis_tvalid;
wire tx_eth_payload_axis_tready;
wire tx_eth_payload_axis_tlast;
wire tx_eth_payload_axis_tuser;


assign phy_reset_n = !rst;

eth_mac_1g_gmii_fifo #(
    .TARGET(TARGET),
    .IODDR_STYLE("IODDR2"),
    .CLOCK_INPUT_STYLE("BUFIO2"),
    .ENABLE_PADDING(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
    .RX_FRAME_FIFO(1)
)
eth_mac_inst (
    .gtx_clk(clk),
    .gtx_rst(rst),
    .logic_clk(clk),
    .logic_rst(rst),

    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),

    .rx_axis_tdata(rx_axis_tdata),
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tready(rx_axis_tready),
    .rx_axis_tlast(rx_axis_tlast),
    .rx_axis_tuser(rx_axis_tuser),

    .gmii_rx_clk(phy_rx_clk),
    .gmii_rxd(phy_rxd),
    .gmii_rx_dv(phy_rx_dv),
    .gmii_rx_er(phy_rx_er),
    .gmii_tx_clk(phy_gtx_clk),
    .mii_tx_clk(phy_tx_clk),
    .gmii_txd(phy_txd),
    .gmii_tx_en(phy_tx_en),
    .gmii_tx_er(phy_tx_er),

    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),
    .speed(),

    .ifg_delay(12)
);

eth_axis_rx
eth_axis_rx_inst (
    .clk(clk),
    .rst(rst),
    // AXI input
    .s_axis_tdata(rx_axis_tdata),
    .s_axis_tvalid(rx_axis_tvalid),
    .s_axis_tready(rx_axis_tready),
    .s_axis_tlast(rx_axis_tlast),
    .s_axis_tuser(rx_axis_tuser),
    // Ethernet frame output
    .m_eth_hdr_valid(rx_eth_hdr_valid),
    .m_eth_hdr_ready(rx_eth_hdr_ready),
    .m_eth_dest_mac(rx_eth_dest_mac),
    .m_eth_src_mac(rx_eth_src_mac),
    .m_eth_type(rx_eth_type),
    .m_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(rx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
    // Status signals
    .busy(),
    .error_header_early_termination()
);

eth_axis_tx
eth_axis_tx_inst (
    .clk(clk),
    .rst(rst),
    // Ethernet frame input
    .s_eth_hdr_valid(tx_eth_hdr_valid),
    .s_eth_hdr_ready(tx_eth_hdr_ready),
    .s_eth_dest_mac(tx_eth_dest_mac),
    .s_eth_src_mac(tx_eth_src_mac),
    .s_eth_type(tx_eth_type),
    .s_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .s_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
    // AXI output
    .m_axis_tdata(tx_axis_tdata),
    .m_axis_tvalid(tx_axis_tvalid),
    .m_axis_tready(tx_axis_tready),
    .m_axis_tlast(tx_axis_tlast),
    .m_axis_tuser(tx_axis_tuser),
    // Status signals
    .busy()
);



eth_pack_fifo
eth_pack_fifo_inst
(
    .ddr_clk(c3_clk0),
    .ddr_rst(c3_rst0),
    
    .eth_clk(clk),
    .eth_rst(rst),

    .s_frame_axis_tdata(8'b1),
    .s_frame_axis_tvalid(1'b1),
    .s_frame_axis_tready(s_frame_axis_tready),

    .m_eth_hdr_valid(tx_eth_hdr_valid),
    .m_eth_hdr_ready(tx_eth_hdr_ready),
    .m_eth_dest_mac(tx_eth_dest_mac),
    .m_eth_src_mac(tx_eth_src_mac),
    .m_eth_type(tx_eth_type),
    .m_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(tx_eth_payload_axis_tuser)
);


endmodule

//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2010 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor:        Xilinx
// \   \   \/    Version:       1.0.0
//  \   \        Filename:      dvi_demo.v
//  /   /        Date Created:  Feb. 2010
// /___/   /\    Last Modified: Feb. 2010
// \   \  /  \
//  \___\/\___\
//
// Devices:   Spartan-6  FPGA
// Purpose:   DVI Pass Through Top Module Based On XLAB Atlys Board
// Contact:   
// Reference: None
//
// Revision History:
//   Rev 1.0.0 - (Bob Feng) First created Feb. 2010
//
//////////////////////////////////////////////////////////////////////////////
//
// LIMITED WARRANTY AND DISCLAIMER. These designs are provided to you "as is".
// Xilinx and its licensors make and you receive no warranties or conditions,
// express, implied, statutory or otherwise, and Xilinx specifically disclaims
// any implied warranties of merchantability, non-infringement, or fitness for
// a particular purpose. Xilinx does not warrant that the functions contained
// in these designs will meet your requirements, or that the operation of
// these designs will be uninterrupted or error free, or that defects in the
// designs will be corrected. Furthermore, Xilinx does not warrant or make any
// representations regarding use or the results of the use of the designs in
// terms of correctness, accuracy, reliability, or otherwise.
//
// LIMITATION OF LIABILITY. In no event will Xilinx or its licensors be liable
// for any loss of data, lost profits, cost or procurement of substitute goods
// or services, or for any special, incidental, consequential, or indirect
// damages arising from the use or operation of the designs or accompanying
// documentation, however caused and on any theory of liability. This
// limitation will apply even if Xilinx has been advised of the possibility
// of such damage. This limitation shall apply not-withstanding the failure
// of the essential purpose of any limited remedies herein.
//
//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2010 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module hdmi_top (
  
    input   wire                rst,

    input   wire                hdmi_rx_clk_p,      
    input   wire                hdmi_rx_clk_n,      
    input   wire    [2:0]       hdmi_rx_p,
    input   wire    [2:0]       hdmi_rx_n,
  
    output  wire    [7:0]       led,

    output wire reset,          // rx reset
    output wire pclk,           // regenerated pixel clock

    output wire hsync,          // hsync data
    output wire vsync,          // vsync data
    output wire de,             // data enable
  
    output wire blue_vld,
    output wire green_vld,
    output wire red_vld,
    output wire blue_rdy,
    output wire green_rdy,
    output wire red_rdy,

    output wire [7:0] red,      // pixel data out
    output wire [7:0] green,    // pixel data out
    output wire [7:0] blue   

);

assign reset = rx0_reset;          
assign pclk = rx0_pclk;          
assign hsync = rx0_hsync;         
assign vsync = rx0_vsync;         
assign de = rx0_de;            
assign blue_vld = rx0_blue_vld;
assign green_vld = rx0_green_vld;
assign red_vld = rx0_red_vld;
assign blue_rdy = rx0_blue_rdy;
assign green_rdy = rx0_green_rdy;
assign red_rdy = rx0_red_rdy;
assign red = rx0_red;     
assign green = rx0_green;   
assign blue = rx0_blue;  

wire rx0_pclk, rx0_pclkx2, rx0_pclkx10, rx0_pllclk0;
wire rx0_plllckd;
wire rx0_pllclk1;
wire rx0_pllclk2;
wire rx0_tmdsclk;
wire rx0_reset;
wire rx0_serdesstrobe;
wire rx0_hsync;          // hsync data
wire rx0_vsync;          // vsync data
wire rx0_de;             // data enable
wire rx0_psalgnerr;      // channel phase alignment error
wire [7:0] rx0_red;      // pixel data out
wire [7:0] rx0_green;    // pixel data out
wire [7:0] rx0_blue;     // pixel data out
wire [29:0] rx0_sdata;
wire rx0_blue_vld;
wire rx0_green_vld;
wire rx0_red_vld;
wire rx0_blue_rdy;
wire rx0_green_rdy;
wire rx0_red_rdy;

dvi_decoder dvi_rx0 (
    //These are input ports
    .tmdsclk_p   (hdmi_rx_clk_p),
    .tmdsclk_n   (hdmi_rx_clk_n),
    .blue_p      (hdmi_rx_p[0]),
    .green_p     (hdmi_rx_p[1]),
    .red_p       (hdmi_rx_p[2]),
    .blue_n      (hdmi_rx_n[0]),
    .green_n     (hdmi_rx_n[1]),
    .red_n       (hdmi_rx_n[2]),
    .exrst       (rst),

    //These are output ports
    .reset       (rx0_reset),
    .pclk        (rx0_pclk),
    .pclkx2      (rx0_pclkx2),
    .pclkx10     (rx0_pclkx10),
    .pllclk0     (rx0_pllclk0), // PLL x10 output
    .pllclk1     (rx0_pllclk1), // PLL x1 output
    .pllclk2     (rx0_pllclk2), // PLL x2 output
    .pll_lckd    (rx0_plllckd),
    .tmdsclk     (rx0_tmdsclk),
    .serdesstrobe(rx0_serdesstrobe),
    .hsync       (rx0_hsync),
    .vsync       (rx0_vsync),
    .de          (rx0_de),

    .blue_vld    (rx0_blue_vld),
    .green_vld   (rx0_green_vld),
    .red_vld     (rx0_red_vld),
    .blue_rdy    (rx0_blue_rdy),
    .green_rdy   (rx0_green_rdy),
    .red_rdy     (rx0_red_rdy),

    .psalgnerr   (rx0_psalgnerr),

    .sdout       (rx0_sdata),
    .red         (rx0_red),
    .green       (rx0_green),
    .blue        (rx0_blue)
); 

/*
* Status LED
*/
assign led = {rx0_red_rdy, rx0_green_rdy, rx0_blue_rdy, rx0_de,3'b0};

endmodule

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

module bench_top;

	// Inputs
reg clk;
reg reset_n;
reg phy_rx_clk;
reg [7:0] phy_rxd;
reg phy_rx_dv;
reg phy_rx_er;
reg phy_tx_clk;
reg uart_rxd;
reg hdmi_rx_clk_p;
reg hdmi_rx_clk_n;
reg [2:0] hdmi_rx_p;
reg [2:0] hdmi_rx_n;

	// Outputs
wire [7:0] led;
wire phy_gtx_clk;
wire [7:0] phy_txd;
wire phy_tx_en;
wire phy_tx_er;
wire phy_reset_n;
wire uart_txd;
wire [12:0] ddr_a;
wire [2:0] ddr_ba;
wire ddr_ras_n;
wire ddr_cas_n;
wire ddr_we_n;
wire ddr_odt;
wire ddr_cke;
wire ddr_dm;
wire ddr_ck;
wire ddr_ck_n;
wire ddr_udm;

	// Bidirs
wire [15:0] ddr_dq;
wire ddr_udqs;
wire ddr_udqs_n;
wire ddr_dqs;
wire ddr_dqs_n;

fpga 
fpga_inst (
	.clk(clk), 
	.reset_n(reset_n), 
	.led(led), 
	.phy_rx_clk(phy_rx_clk), 
	.phy_rxd(phy_rxd), 
	.phy_rx_dv(phy_rx_dv), 
	.phy_rx_er(phy_rx_er), 
	.phy_gtx_clk(phy_gtx_clk), 
	.phy_tx_clk(phy_tx_clk), 
	.phy_txd(phy_txd), 
	.phy_tx_en(phy_tx_en), 
	.phy_tx_er(phy_tx_er), 
	.phy_reset_n(phy_reset_n), 
	.uart_rxd(uart_rxd), 
	.uart_txd(uart_txd), 
	.hdmi_rx_clk_p(hdmi_rx_clk_p), 
	.hdmi_rx_clk_n(hdmi_rx_clk_n), 
	.hdmi_rx_p(hdmi_rx_p), 
	.hdmi_rx_n(hdmi_rx_n), 
	.ddr_dq(ddr_dq), 
	.ddr_a(ddr_a), 
	.ddr_ba(ddr_ba), 
	.ddr_ras_n(ddr_ras_n), 
	.ddr_cas_n(ddr_cas_n), 
	.ddr_we_n(ddr_we_n), 
	.ddr_odt(ddr_odt), 
	.ddr_cke(ddr_cke), 
	.ddr_dm(ddr_dm), 
	.ddr_udqs(ddr_udqs), 
	.ddr_udqs_n(ddr_udqs_n), 
	.ddr_dqs(ddr_dqs), 
	.ddr_dqs_n(ddr_dqs_n), 
	.ddr_ck(ddr_ck), 
	.ddr_ck_n(ddr_ck_n), 
	.ddr_udm(ddr_udm)
);


ddr2
ddr2_inst (
    .ck(ddr_ck),
    .ck_n(ddr_ck_n),
    .cke(ddr_cke),
    .cs_n(1'b0),
    .ras_n(ddr_ras_n),
    .cas_n(ddr_cas_n),
    .we_n(ddr_we_n),
    .dm_rdqs(ddr_udqs),
    .ba(ddr_ba),
    .addr(ddr_a),
    .dq(ddr_dq),
    .dqs(ddr_dqs),
    .dqs_n(ddr_dqs_n),
    .rdqs_n(ddr_udqs_n),
    .odt(ddr_odt)
);

always #5 clk <= !clk;

initial begin
	// Initialize Inputs
	clk = 0;
	reset_n = 0;
	phy_rx_clk = 0;
	phy_rxd = 0;
	phy_rx_dv = 0;
	phy_rx_er = 0;
	phy_tx_clk = 0;
	uart_rxd = 0;
	hdmi_rx_clk_p = 0;
	hdmi_rx_clk_n = 0;
	hdmi_rx_p = 0;
	hdmi_rx_n = 0;

	// Wait 100 ns for global reset to finish
	#100;
	reset_n = 1;

end
      
endmodule


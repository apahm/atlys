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
 * FPGA top-level module
 */
module fpga (
    /*
     * Clock: 100MHz
     * Reset: Push button, active low
     */
    input   wire                clk,
    input   wire                reset_n,

    /*
     * GPIO
     */
    output  wire    [7:0]       led,

    /*
     * Ethernet: 1000BASE-T GMII
     */
    input   wire                phy_rx_clk,
    input   wire    [7:0]       phy_rxd,
    input   wire                phy_rx_dv,
    input   wire                phy_rx_er,
    output  wire                phy_gtx_clk,
    input   wire                phy_tx_clk,
    output  wire    [7:0]       phy_txd,
    output  wire                phy_tx_en,
    output  wire                phy_tx_er,
    output  wire                phy_reset_n,

    /*
     * UART: 115200 bps, 8N1
     */
    input   wire                uart_rxd,
    output  wire                uart_txd,

    /*
     * HDMI: Receive port J3
     */
    
    input   wire                hdmi_rx_clk_p,      
    input   wire                hdmi_rx_clk_n,      
    input   wire    [2:0]       hdmi_rx_p,
    input   wire    [2:0]       hdmi_rx_n,
    input   wire                hdmi_rx_scl,
    inout   wire                hdmi_rx_sda,

    /*
     * DDR2: MIRA P3R1GE3EGF G8E DDR2 
     */
    inout   wire     [15:0]     ddr_dq,
    output  wire     [12:0]     ddr_a,
    output  wire     [2:0]      ddr_ba,
    output  wire                ddr_ras_n,
    output  wire                ddr_cas_n,
    output  wire                ddr_we_n,
    output  wire                ddr_odt,
    output  wire                ddr_cke,
    output  wire                ddr_dm,
    inout   wire                ddr_udqs,
    inout   wire                ddr_udqs_n,
    inout   wire                ddr_dqs,
    inout   wire                ddr_dqs_n,
    output  wire                ddr_ck,
    output  wire                ddr_ck_n,
    output  wire                ddr_udm
);


// Clock and reset

wire clk_ibufg;

// Internal 125 MHz clock
wire clk_dcm_out;
wire clk_int;
wire clk_ddr;
wire rst_int;

wire dcm_rst;
wire [7:0] dcm_status;
wire dcm_locked;
wire dcm_clkfx_stopped = dcm_status[2];

assign dcm_rst = ~reset_n | (dcm_clkfx_stopped & ~dcm_locked);

IBUFG
clk_ibufg_inst(
    .I(clk),
    .O(clk_ibufg)
);

DCM_SP #(
    .CLKIN_PERIOD(10),
    .CLK_FEEDBACK("NONE"),
    .CLKDV_DIVIDE(2.0),
    .CLKFX_MULTIPLY(5.0),
    .CLKFX_DIVIDE(4.0),
    .PHASE_SHIFT(0),
    .CLKOUT_PHASE_SHIFT("NONE"),
    .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
    .STARTUP_WAIT("FALSE"),
    .CLKIN_DIVIDE_BY_2("FALSE")
)
clk_dcm_inst (
    .CLKIN(clk_ibufg),
    .CLKFB(1'b0),
    .RST(dcm_rst),
    .PSEN(1'b0),
    .PSINCDEC(1'b0),
    .PSCLK(1'b0),
    .CLK0(),
    .CLK90(),
    .CLK180(),
    .CLK270(),
    .CLK2X(clk_ddr),
    .CLK2X180(),
    .CLKDV(),
    .CLKFX(clk_dcm_out),
    .CLKFX180(),
    .STATUS(dcm_status),
    .LOCKED(dcm_locked),
    .PSDONE()
);

BUFG
clk_bufg_inst (
    .I(clk_dcm_out),
    .O(clk_int)
);

sync_reset #(
    .N(4)
)
sync_reset_inst (
    .clk(clk_int),
    .rst(~dcm_locked),
    .out(rst_int)
);

wire uart_rxd_int;

sync_signal #(
    .WIDTH(1),
    .N(2)
)
sync_signal_inst (
    .clk(clk_int),
    .in({uart_rxd}),
    .out({uart_rxd_int})
);


i2c_edid# (
	.HEX_FILE("/home/alex/atlys/hex/AOC.hex")
) 
i2c_edid_inst 
(
	.clk(clk_int),
	.rst(rst_int),
	.scl(hdmi_rx_scl),
	.sda(hdmi_rx_sda)
);

fpga_core #(
    .TARGET("XILINX"),
    .MIG_SIM("TRUE")
)
core_inst (

    .clk(clk_int),
    .rst(rst_int),

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

    .uart_rxd(uart_rxd_int),
    .uart_txd(uart_txd),

    .hdmi_rx_clk_p  (hdmi_rx_clk_p),      
    .hdmi_rx_clk_n  (hdmi_rx_clk_n),      
    .hdmi_rx_p      (hdmi_rx_p),
    .hdmi_rx_n      (hdmi_rx_n),

    .ddr_clk        (clk_int),
    .ddr_rst        (rst_int),
    .ddr_dq         (ddr_dq),
    .ddr_a          (ddr_a),
    .ddr_ba         (ddr_ba),
    .ddr_ras_n      (ddr_ras_n),
    .ddr_cas_n      (ddr_cas_n),
    .ddr_we_n       (ddr_we_n),
    .ddr_odt        (ddr_odt),
    .ddr_cke        (ddr_cke),
    .ddr_dm         (ddr_dm),
    .ddr_udqs       (ddr_udqs),
    .ddr_udqs_n     (ddr_udqs_n),
    .ddr_dqs        (ddr_dqs),
    .ddr_dqs_n      (ddr_dqs_n),
    .ddr_ck         (ddr_ck),
    .ddr_ck_n       (ddr_ck_n),
    .ddr_udm        (ddr_udm)
);

endmodule

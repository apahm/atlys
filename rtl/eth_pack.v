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

module eth_pack
(
    input   wire         clk,
    input   wire         rst,

    input   wire [7:0]   s_fifo_axis_tdata,
    input   wire         s_fifo_axis_tvalid,
    output  wire         s_fifo_axis_tready,
    input   wire         s_fifo_wr_data_count,
    input   wire         s_fifo_rd_data_count,
    /*
     * Ethernet frame output
     */
    output  wire         m_eth_hdr_valid,
    input   wire         m_eth_hdr_ready,
    output  wire [47:0]  m_eth_dest_mac,
    output  wire [47:0]  m_eth_src_mac,
    output  wire [15:0]  m_eth_type,
    output  wire [7:0]   m_eth_payload_axis_tdata,
    output  wire         m_eth_payload_axis_tvalid,
    input   wire         m_eth_payload_axis_tready,
    output  wire         m_eth_payload_axis_tlast,
    output  wire         m_eth_payload_axis_tuser
);


localparam [2:0]
    STATE_IDLE = 3'd0,
    STATE_WRITE_HEADER = 3'd1,
    STATE_WRITE_PAYLOAD = 3'd2,
    STATE_WRITE_PAYLOAD_LAST = 3'd3,
    STATE_WAIT_LAST = 3'd4;

reg [2:0] state_reg = STATE_IDLE, state_next;

// datapath control signals
reg store_last_word;

reg [5:0] hdr_ptr_reg = 6'd0, hdr_ptr_next;
reg [15:0] word_count_reg = 16'd0, word_count_next;

reg [7:0] last_word_data_reg = 8'd0;

reg s_ip_payload_axis_tready_reg = 1'b0, s_ip_payload_axis_tready_next;

reg m_eth_hdr_valid_reg = 1'b0, m_eth_hdr_valid_next;
reg [47:0] m_eth_dest_mac_reg = 48'd0;
reg [47:0] m_eth_src_mac_reg = 48'd0;
reg [15:0] m_eth_type_reg = 16'd0;

// internal datapath
reg [7:0] m_eth_payload_axis_tdata_int;
reg       m_eth_payload_axis_tvalid_int;
reg       m_eth_payload_axis_tready_int_reg = 1'b0;
reg       m_eth_payload_axis_tlast_int;
reg       m_eth_payload_axis_tuser_int;
wire      m_eth_payload_axis_tready_int_early;

assign s_ip_payload_axis_tready = s_ip_payload_axis_tready_reg;

assign m_eth_hdr_valid = m_eth_hdr_valid_reg;
assign m_eth_dest_mac = m_eth_dest_mac_reg;
assign m_eth_src_mac = m_eth_src_mac_reg;
assign m_eth_type = m_eth_type_reg;


always @* begin
    state_next = STATE_IDLE;

    s_ip_payload_axis_tready_next = 1'b0;

    store_last_word = 1'b0;

    hdr_ptr_next = hdr_ptr_reg;
    word_count_next = word_count_reg;

    m_eth_hdr_valid_next = m_eth_hdr_valid_reg && !m_eth_hdr_ready;

    m_eth_payload_axis_tdata_int = 8'd0;
    m_eth_payload_axis_tvalid_int = 1'b0;
    m_eth_payload_axis_tlast_int = 1'b0;
    m_eth_payload_axis_tuser_int = 1'b0;

    case (state_reg)
        STATE_IDLE: begin
            // idle state - wait for data
            hdr_ptr_next = 6'd0;

            if () begin
                s_ip_hdr_ready_next = 1'b0;
                m_eth_hdr_valid_next = 1'b1;
                if (m_eth_payload_axis_tready_int_reg) begin
                    m_eth_payload_axis_tvalid_int = 1'b1;
                    m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    hdr_ptr_next = 6'd1;
                end
                state_next = STATE_WRITE_HEADER;
            end else begin
                state_next = STATE_IDLE;
            end
        end
        STATE_WRITE_HEADER: begin
            // write header
            word_count_next = 16'd512;

            if (m_eth_payload_axis_tready_int_reg) begin
                hdr_ptr_next = hdr_ptr_reg + 6'd1;
                m_eth_payload_axis_tvalid_int = 1;
                state_next = STATE_WRITE_HEADER;
                case (hdr_ptr_reg)
                    6'h00: begin
                        m_eth_payload_axis_tdata_int = hdr_ptr_reg; // ip_version, ip_ihl
                    end
                    6'h01: begin
                        m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    end
                    6'h02: begin
                        m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    end
                    6'h03: begin
                        m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    end
                    6'h04: begin
                        m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    end
                    6'h05: begin
                        m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    end
                    6'h06: begin
                        m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    end
                    6'h07: begin
                        m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    end
                    6'h08: m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    6'h09: m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    6'h0A: m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    6'h0B: m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    6'h0C: m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    6'h0D: m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    6'h0E: m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    6'h0F: m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    6'h10: m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    6'h11: m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    6'h12: m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                    6'h13: begin
                        m_eth_payload_axis_tdata_int = hdr_ptr_reg;
                        s_ip_payload_axis_tready_next = m_eth_payload_axis_tready_int_early;
                        state_next = STATE_WRITE_PAYLOAD;
                    end
                endcase
            end else begin
                state_next = STATE_WRITE_HEADER;
            end
        end
        STATE_WRITE_PAYLOAD: begin
            // write payload
            s_ip_payload_axis_tready_next = m_eth_payload_axis_tready_int_early;

            m_eth_payload_axis_tdata_int = s_ip_payload_axis_tdata;
            m_eth_payload_axis_tvalid_int = s_ip_payload_axis_tvalid;
            m_eth_payload_axis_tlast_int = s_ip_payload_axis_tlast;
            m_eth_payload_axis_tuser_int = s_ip_payload_axis_tuser;

            if (s_ip_payload_axis_tready && s_ip_payload_axis_tvalid) begin
                // word transfer through
                word_count_next = word_count_reg - 6'd1;
                if (s_ip_payload_axis_tlast) begin
                    if (word_count_reg != 16'd1) begin
                        // end of frame, but length does not match
                        m_eth_payload_axis_tuser_int = 1'b1;
                        error_payload_early_termination_next = 1'b1;
                    end
                    s_ip_hdr_ready_next = !m_eth_hdr_valid_next;
                    s_ip_payload_axis_tready_next = 1'b0;
                    state_next = STATE_IDLE;
                end else begin
                    if (word_count_reg == 16'd1) begin
                        store_last_word = 1'b1;
                        m_eth_payload_axis_tvalid_int = 1'b0;
                        state_next = STATE_WRITE_PAYLOAD_LAST;
                    end else begin
                        state_next = STATE_WRITE_PAYLOAD;
                    end
                end
            end else begin
                state_next = STATE_WRITE_PAYLOAD;
            end
        end
        STATE_WRITE_PAYLOAD_LAST: begin
            // read and discard until end of frame
            s_ip_payload_axis_tready_next = m_eth_payload_axis_tready_int_early;

            m_eth_payload_axis_tdata_int = last_word_data_reg;
            m_eth_payload_axis_tvalid_int = s_ip_payload_axis_tvalid && s_ip_payload_axis_tlast;
            m_eth_payload_axis_tlast_int = s_ip_payload_axis_tlast;
            m_eth_payload_axis_tuser_int = s_ip_payload_axis_tuser;

            if (s_ip_payload_axis_tready && s_ip_payload_axis_tvalid) begin
                if (s_ip_payload_axis_tlast) begin
                    s_ip_hdr_ready_next = !m_eth_hdr_valid_next;
                    s_ip_payload_axis_tready_next = 1'b0;
                    state_next = STATE_IDLE;
                end else begin
                    state_next = STATE_WRITE_PAYLOAD_LAST;
                end
            end else begin
                state_next = STATE_WRITE_PAYLOAD_LAST;
            end
        end
        STATE_WAIT_LAST: begin
            // read and discard until end of frame
            s_ip_payload_axis_tready_next = 1'b1;

            if (s_ip_payload_axis_tready && s_ip_payload_axis_tvalid) begin
                if (s_ip_payload_axis_tlast) begin
                    s_ip_hdr_ready_next = !m_eth_hdr_valid_next;
                    s_ip_payload_axis_tready_next = 1'b0;
                    state_next = STATE_IDLE;
                end else begin
                    state_next = STATE_WAIT_LAST;
                end
            end else begin
                state_next = STATE_WAIT_LAST;
            end
        end
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        state_reg <= STATE_IDLE;
        s_ip_payload_axis_tready_reg <= 1'b0;
        m_eth_hdr_valid_reg <= 1'b0;
    end else begin
        state_reg <= state_next;

        s_ip_payload_axis_tready_reg <= s_ip_payload_axis_tready_next;

        m_eth_hdr_valid_reg <= m_eth_hdr_valid_next;

    end

    hdr_ptr_reg <= hdr_ptr_next;
    word_count_reg <= word_count_next;

    if (store_last_word) begin
        last_word_data_reg <= m_eth_payload_axis_tdata_int;
    end
end

// output datapath logic
reg [7:0] m_eth_payload_axis_tdata_reg = 8'd0;
reg       m_eth_payload_axis_tvalid_reg = 1'b0, m_eth_payload_axis_tvalid_next;
reg       m_eth_payload_axis_tlast_reg = 1'b0;
reg       m_eth_payload_axis_tuser_reg = 1'b0;

reg [7:0] temp_m_eth_payload_axis_tdata_reg = 8'd0;
reg       temp_m_eth_payload_axis_tvalid_reg = 1'b0, temp_m_eth_payload_axis_tvalid_next;
reg       temp_m_eth_payload_axis_tlast_reg = 1'b0;
reg       temp_m_eth_payload_axis_tuser_reg = 1'b0;

// datapath control
reg store_eth_payload_int_to_output;
reg store_eth_payload_int_to_temp;
reg store_eth_payload_axis_temp_to_output;

assign m_eth_payload_axis_tdata = m_eth_payload_axis_tdata_reg;
assign m_eth_payload_axis_tvalid = m_eth_payload_axis_tvalid_reg;
assign m_eth_payload_axis_tlast = m_eth_payload_axis_tlast_reg;
assign m_eth_payload_axis_tuser = m_eth_payload_axis_tuser_reg;

// enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
assign m_eth_payload_axis_tready_int_early = m_eth_payload_axis_tready || (!temp_m_eth_payload_axis_tvalid_reg && (!m_eth_payload_axis_tvalid_reg || !m_eth_payload_axis_tvalid_int));

always @* begin
    // transfer sink ready state to source
    m_eth_payload_axis_tvalid_next = m_eth_payload_axis_tvalid_reg;
    temp_m_eth_payload_axis_tvalid_next = temp_m_eth_payload_axis_tvalid_reg;

    store_eth_payload_int_to_output = 1'b0;
    store_eth_payload_int_to_temp = 1'b0;
    store_eth_payload_axis_temp_to_output = 1'b0;
    
    if (m_eth_payload_axis_tready_int_reg) begin
        // input is ready
        if (m_eth_payload_axis_tready || !m_eth_payload_axis_tvalid_reg) begin
            // output is ready or currently not valid, transfer data to output
            m_eth_payload_axis_tvalid_next = m_eth_payload_axis_tvalid_int;
            store_eth_payload_int_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_m_eth_payload_axis_tvalid_next = m_eth_payload_axis_tvalid_int;
            store_eth_payload_int_to_temp = 1'b1;
        end
    end else if (m_eth_payload_axis_tready) begin
        // input is not ready, but output is ready
        m_eth_payload_axis_tvalid_next = temp_m_eth_payload_axis_tvalid_reg;
        temp_m_eth_payload_axis_tvalid_next = 1'b0;
        store_eth_payload_axis_temp_to_output = 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        m_eth_payload_axis_tvalid_reg <= 1'b0;
        m_eth_payload_axis_tready_int_reg <= 1'b0;
        temp_m_eth_payload_axis_tvalid_reg <= 1'b0;
    end else begin
        m_eth_payload_axis_tvalid_reg <= m_eth_payload_axis_tvalid_next;
        m_eth_payload_axis_tready_int_reg <= m_eth_payload_axis_tready_int_early;
        temp_m_eth_payload_axis_tvalid_reg <= temp_m_eth_payload_axis_tvalid_next;
    end

    // datapath
    if (store_eth_payload_int_to_output) begin
        m_eth_payload_axis_tdata_reg <= m_eth_payload_axis_tdata_int;
        m_eth_payload_axis_tlast_reg <= m_eth_payload_axis_tlast_int;
        m_eth_payload_axis_tuser_reg <= m_eth_payload_axis_tuser_int;
    end else if (store_eth_payload_axis_temp_to_output) begin
        m_eth_payload_axis_tdata_reg <= temp_m_eth_payload_axis_tdata_reg;
        m_eth_payload_axis_tlast_reg <= temp_m_eth_payload_axis_tlast_reg;
        m_eth_payload_axis_tuser_reg <= temp_m_eth_payload_axis_tuser_reg;
    end

    if (store_eth_payload_int_to_temp) begin
        temp_m_eth_payload_axis_tdata_reg <= m_eth_payload_axis_tdata_int;
        temp_m_eth_payload_axis_tlast_reg <= m_eth_payload_axis_tlast_int;
        temp_m_eth_payload_axis_tuser_reg <= m_eth_payload_axis_tuser_int;
    end
end

endmodule
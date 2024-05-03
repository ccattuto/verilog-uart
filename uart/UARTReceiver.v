//
// Simple Verilog implementation of an UART receiver
//
//  - 8N1 only (8-bit data word, 1 start bit, 1 stop bit)
//  - "valid" goes high after successful RX and stays high for at least 1 clock cycle
//  - "valid" is cleared as soon as a high "ready" is detected
//  - internal baud rate generation
//  - 16x baud rate oversampling, majority voting over 3 samples for bit sensing
//  - buffered read: a new RX can start before the last byte has been read
//  - tested on an FPGA at 115200 baud driven by a 48 MHz clock
//
//
// MIT License
//
// Copyright (c) 2024 Ciro Cattuto <ciro.cattuto@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Originally based on Dmitry Pchelkin's verilog-uart (https://github.com/hell03end/verilog-uart)
//

 // states of state machine
`define RESET       3'b001
`define IDLE        3'b010
`define DATA_BITS   3'b100
`define STOP_BIT    3'b101

module UARTReceiver #(
    parameter CLOCK_RATE = 50000000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,      // clock
    input  wire       reset,    // reset
    input  wire       enable,   // enable
    input  wire       in,       // RX line
    input  wire       ready,    // OK to transmit
    output reg  [7:0] out,      // received data
    output reg        valid,    // RX completed
    output reg        error,    // frame error
    output reg        overrun   // overrun
);
    parameter RX_CLOCK_PERIOD = CLOCK_RATE / (BAUD_RATE * 16); // 16x oversample
    parameter RX_CNT_WIDTH = $clog2(RX_CLOCK_PERIOD);
    reg [RX_CNT_WIDTH - 1:0] rxCounter = 0;

    reg [2:0] state = `RESET;
    reg [2:0] bitIndex = 3'b0; // for 8-bit data
    reg [2:0] inputReg = 3'b111; // shift reg for input signal state
    reg [3:0] clockCount = 4'b0; // count clocks for 16x oversample
    reg [7:0] data = 8'b0; // temporary storage for input data

    always @(posedge clk) begin
        if (reset || !enable) begin
            state <= `RESET;
            rxCounter <= 0;
        end else if (rxCounter < RX_CLOCK_PERIOD - 1) begin
            // RX clock
            rxCounter <= rxCounter + 1;
            if (ready) begin
                valid <= 0;
            end
        end else begin
            rxCounter <= 0;

            inputReg <= { inputReg[1], inputReg[0], in };

            case (state)
                `RESET: begin
                    out <= 8'b0;
                    error <= 0;
                    overrun <= 0;
                    valid <= 0;
                    inputReg <= 3'b111;
                    bitIndex <= 3'b0;
                    clockCount <= 4'b0;
                    data <= 8'b0;
                    if (enable) begin
                        state <= `IDLE;
                    end
                end

                `IDLE: begin
                    if (clockCount >= 4'h5) begin
                        state <= `DATA_BITS;
                        bitIndex <= 3'b0;
                        clockCount <= 4'b0;
                        data <= 8'b0;
                        error <= 0;
                        overrun <= 0;
                    end else if (!(|inputReg) || (|clockCount)) begin
                        // Check bit to make sure it's still low
                        if (|inputReg) begin
                            error <= 1;
                            state <= `RESET;
                        end
                        clockCount <= clockCount + 1;
                    end
                end

                // receive 8 bits of data
                `DATA_BITS: begin
                    if (&clockCount) begin // save one bit of received data
                        clockCount <= 4'b0;
                        data[bitIndex] <= (inputReg[0] & inputReg[1]) | (inputReg[0] & inputReg[2]) | (inputReg[1] & inputReg[2]);
                        if (&bitIndex) begin
                            bitIndex <= 3'b0;
                            state <= `STOP_BIT;
                        end else begin
                            bitIndex <= bitIndex + 1;
                        end
                    end else begin
                        clockCount <= clockCount + 1;
                    end
                end

                `STOP_BIT: begin
                    if (&clockCount) begin
                        if (&inputReg) begin
                            valid <= 1;
                            if (!valid) begin
                                out <= data;
                            end else begin
                                overrun <= 1;
                            end
                            state <= `IDLE;
                        end
                    end
                    clockCount <= clockCount + 1;
                end

                default: state <= `RESET;
            endcase
        end
    end

endmodule
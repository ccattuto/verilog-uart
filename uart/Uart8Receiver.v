//
// Simple Verilog implementation of an UART receiver
//
//  - 8N1 only (8-bit data word, 1 start bit, 1 stop bit)
//  - "valid" goes high for exactly 1 clock cycle after successful RX 
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
`define WAIT_STOP   3'b101
`define STOP_BIT    3'b110

module UARTReceiver #(
    parameter CLOCK_RATE = 50000000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,      // clock
    input  wire       reset,    // reset
    input  wire       en,       // enable
    input  wire       in,       // RX line
    output reg  [7:0] out,      // received data
    output reg        valid,    // RX completed
    output reg        err       // error while receiving data
);
    parameter MAX_RATE_RX = CLOCK_RATE / (BAUD_RATE * 16); // 16x oversample
    parameter RX_CNT_WIDTH = $clog2(MAX_RATE_RX);
    reg [RX_CNT_WIDTH - 1:0] rxCounter = 0;

    reg [2:0] state = `RESET;
    reg [2:0] bitIdx = 3'b0; // for 8-bit data
    reg [2:0] inputSw = 3'b111; // shift reg for input signal state
    reg [3:0] clockCount = 4'b0; // count clocks for 16x oversample
    reg [7:0] receivedData = 8'b0; // temporary storage for input data

    initial begin
        out <= 8'b0;
        err <= 0;
        valid <= 0;
        inputSw = 3'b111;
    end

    always @(posedge clk) begin
        if (reset || !en) begin
            state <= `RESET;
            rxCounter <= 0;
        end else if (rxCounter < MAX_RATE_RX - 1) begin
            // RX clock
            rxCounter <= rxCounter + 1;
            valid <= 0; // make sure valid flag stays high for only 1 clock cycle
        end else begin
            rxCounter <= 0;

            inputSw <= { inputSw[1], inputSw[0], in };

            case (state)
                `RESET: begin
                    out <= 8'b0;
                    err <= 0;
                    valid <= 0;
                    inputSw <= 3'b111;
                    bitIdx <= 3'b0;
                    clockCount <= 4'b0;
                    receivedData <= 8'b0;
                    if (en) begin
                        state <= `IDLE;
                    end
                end

                `IDLE: begin
                    valid <= 0;
                    if (clockCount >= 4'h5) begin
                        state <= `DATA_BITS;
                        out <= 8'b0;
                        bitIdx <= 3'b0;
                        clockCount <= 4'b0;
                        receivedData <= 8'b0;
                        err <= 0;
                    end else if (!(|inputSw) || (|clockCount)) begin
                        // Check bit to make sure it's still low
                        if (|inputSw) begin
                            err <= 1;
                            state <= `RESET;
                        end
                        clockCount <= clockCount + 1;
                    end
                end

                // receive 8 bits of data
                `DATA_BITS: begin
                    if (&clockCount) begin // save one bit of received data
                        clockCount <= 4'b0;
                        receivedData[bitIdx] <= (inputSw[0] & inputSw[1]) | (inputSw[0] & inputSw[2]) | (inputSw[1] & inputSw[2]);
                        if (&bitIdx) begin
                            bitIdx <= 3'b0;
                            state <= `WAIT_STOP;
                        end else begin
                            bitIdx <= bitIdx + 1;
                        end
                    end else begin
                        clockCount <= clockCount + 1;
                    end
                end

                `WAIT_STOP: begin
                    if (&clockCount) begin
                        clockCount <= 4'b0;
                        state <= `STOP_BIT;
                    end else begin
                        clockCount <= clockCount + 1;
                    end
                end

                // check for at least half a stop bit
                `STOP_BIT: begin
                    if (clockCount == 4'h8) begin
                        state <= `IDLE;
                        valid <= 1;
                        out <= receivedData;
                        clockCount <= 4'b0;
                    end else begin
                        clockCount <= clockCount + 1;
                        // Check bit to make sure it's still high
                        if (!(&inputSw)) begin
                            err <= 1;
                            state <= `RESET;
                        end
                    end
                end

                default: state <= `RESET;
            endcase
        end
    end

endmodule

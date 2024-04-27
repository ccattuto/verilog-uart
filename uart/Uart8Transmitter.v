`include "UartStates.vh"

/*
 * 8-bit UART Transmitter.
 * Able to transmit 8 bits of serial data, one start bit, one stop bit.
 * Transmit starts when {valid} is asserted.
 * When transmit is in progress {ready} is driven low.
 * Clock should be decreased to baud rate.
 */
module Uart8Transmitter (
    input  wire       clk,   // baud rate
    input  wire       en,    // TX enable
    input  wire       valid, // start transaction
    input  wire [7:0] in,    // data to transmit
    output reg        out,   // TX line
    output reg        ready, // ready to TX
);
    reg [2:0] state  = `RESET;
    reg [7:0] data   = 8'b0; // to store a copy of input data
    reg [2:0] bitIdx = 3'b0; // for 8-bit data

    always @(posedge clk) begin
        case (state)
            default     : begin
                state   <= `IDLE;
            end
            
            `IDLE       : begin
                out     <= 1'b1; // drive line high for idle
                ready   <= 1'b1;
                bitIdx  <= 3'b0;
                data    <= 8'b0;
                if (valid & en) begin
                    data    <= in; // save a copy of input data
                    ready   <= 1'b0;
                    state   <= `START_BIT;
                end
            end

            `START_BIT  : begin
                out     <= 1'b0; // send start bit (low)
                state   <= `DATA_BITS;
            end

            `DATA_BITS  : begin // Wait 8 clock cycles for data bits to be sent
                out     <= data[bitIdx];
                if (&bitIdx) begin
                    bitIdx  <= 3'b0;
                    state   <= `STOP_BIT;
                end else begin
                    bitIdx  <= bitIdx + 1'b1;
                end
            end

            `STOP_BIT   : begin // Send out Stop bit (high)
                out     <= 1'b1;
                state   <= `IDLE;
            end
        endcase
    end

endmodule

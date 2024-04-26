`include "UartStates.vh"

/*
 * 8-bit UART Receiver.
 * Able to receive 8 bits of serial data, one start bit, one stop bit.
 * When receive is complete {done} is driven high for one clock cycle.
 * Output data should be taken away by a few clocks or can be lost.
 * When receive is in progress {busy} is driven high.
 * Clock should be decreased to baud rate.
 */
module Uart8Receiver (
    input  wire       clk,  // baud rate
    input  wire       en,
    input  wire       in,   // rx
    output reg  [7:0] out,  // received data
    output reg        done, // end on transaction
    output reg        busy, // transaction is in process
    output reg        err   // error while receiving data
);
    reg [2:0] state = `RESET;
    reg [2:0] bitIdx = 3'b0; // for 8-bit data
    reg [2:0] inputSw = 3'b111; // shift reg for input signal state
    reg [3:0] clockCount = 4'b0; // count clocks for 16x oversample
    reg [7:0] receivedData = 8'b0; // temporary storage for input data

    initial begin
        out <= 8'b0;
        err <= 1'b0;
        done <= 1'b0;
        busy <= 1'b0;
        inputSw = 3'b111;
    end

    always @(posedge clk) begin
        inputSw <= { inputSw[1], inputSw[0], in };

        if (!en) begin
            state <= `RESET;
        end

        case (state)
            `RESET: begin
                out <= 8'b0;
                err <= 1'b0;
                done <= 1'b0;
                busy <= 1'b0;
                bitIdx <= 3'b0;
                clockCount <= 4'b0;
                receivedData <= 8'b0;
                inputSw <= 3'b111;
                if (en) begin
                    state <= `IDLE;
                end
            end

            `IDLE: begin
                done <= 1'b0;
                if (clockCount >= 4'h5) begin
                    state <= `DATA_BITS;
                    out <= 8'b0;
                    bitIdx <= 3'b0;
                    clockCount <= 4'b0;
                    receivedData <= 8'b0;
                    busy <= 1'b1;
                    err <= 1'b0;
                end else if (!(|inputSw) || (|clockCount)) begin
                    // Check bit to make sure it's still low
                    if (|inputSw) begin
                        err <= 1'b1;
                        state <= `RESET;
                    end
                    clockCount <= clockCount + 4'b1;
                end
            end

            // Wait 8 full cycles to receive serial data
            `DATA_BITS: begin
                if (&clockCount) begin // save one bit of received data
                    clockCount <= 4'b0;
                    receivedData[bitIdx] <= (inputSw[0] & inputSw[1]) | (inputSw[0] & inputSw[2]) | (inputSw[1] & inputSw[2]);
                    if (&bitIdx) begin
                        bitIdx <= 3'b0;
                        state <= `WAIT_STOP;
                    end else begin
                        bitIdx <= bitIdx + 3'b1;
                    end
                end else begin
                    clockCount <= clockCount + 4'b1;
                end
            end

            `WAIT_STOP: begin
                if (&clockCount) begin
                    clockCount <= 4'b0;
                    state <= `STOP_BIT;
                end else begin
                    clockCount <= clockCount + 4'b1;
                end
            end

            /*
            * Baud clock may not be running at exactly the same rate as the
            * transmitter. Next start bit is allowed on at least half of stop bit.
            */
            `STOP_BIT: begin
                if (clockCount == 4'h8) begin
                    state <= `IDLE;
                    done <= 1'b1;
                    busy <= 1'b0;
                    out <= receivedData;
                    clockCount <= 4'b0;
                end else begin
                    clockCount <= clockCount + 1;
                    // Check bit to make sure it's still high
                    if (!(&inputSw)) begin
                        err <= 1'b1;
                        state <= `RESET;
                    end
                end
            end

            default: state <= `IDLE;
        endcase
    end

endmodule

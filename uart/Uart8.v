/*
 * Simple 8-bit UART realization.
 * Combine receiver, transmitter and baud rate generator.
 * Able to operate 8 bits of serial data, one start bit, one stop bit.
 */
module Uart8  #(
    parameter CLOCK_RATE = 100000000, // board internal clock
    parameter BAUD_RATE = 9600
)(
    input wire clk,

    // rx interface
    input wire rx,
    input wire rxEn,
    output wire [7:0] out,
    output wire rxValid,
    output wire rxReady,
    output wire rxErr,
    
    // tx interface
    output wire tx,
    input wire txEn,
    input wire [7:0] in,
    input wire txValid,
    output wire txReady
);
wire rxClk;
wire txClk;

BaudRateGenerator #(
    .CLOCK_RATE(CLOCK_RATE),
    .BAUD_RATE(BAUD_RATE)
) generatorInst (
    .clk(clk),
    .rxClk(rxClk),
    .txClk(txClk)
);

Uart8Receiver rxInst (
    .clk(rxClk),
    .en(rxEn),
    .in(rx),
    .out(out),
    .valid(rxValid),
    .ready(rxReady),
    .err(rxErr)
);

Uart8Transmitter txInst (
    .clk(txClk),
    .en(txEn),
    .in(in),
    .out(tx),
    .valid(txValid),
    .ready(txReady)
);

endmodule

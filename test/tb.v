module test_uart ();

// TRANSMITTER

wire tx_enable;
assign tx_enable = 1;

wire clk, tx_reset, tx_valid, tx_ready;
wire [7:0] tx_data;
wire uart_tx;

UARTTransmitter #(
    .CLOCK_RATE(24000000),
    .BAUD_RATE(115200)
) uart_transmitter (
    .clk(clk),              // clock
    .reset(tx_reset),       // reset
    .enable(tx_enable),     // TX enable
    .valid(tx_valid),       // start transaction
    .in(tx_data),           // data to transmit
    .out(uart_tx),          // TX line
    .ready(tx_ready)        // ready for TX
);


// RECEIVER

wire rx_enable;
assign rx_enable = 1;

wire rx_reset, rx_valid, rx_ready, rx_error, rx_overrun;
wire [7:0] rx_data;
wire uart_rx;

UARTReceiver #(
    .CLOCK_RATE(24000000),
    .BAUD_RATE(115200)
) uart_receiver (
    .clk(clk),              // clock
    .reset(rx_reset),       // reset
    .enable(rx_enable),     // enable
    .in(uart_rx),           // RX line
    .ready(rx_ready),       // OK to transmit
    .out(rx_data),          // received data
    .valid(rx_valid),       // RX completed
    .error(rx_error),           // error while receiving data
    .overrun(rx_overrun)
);

endmodule

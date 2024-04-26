verilog-uart
============
Simple 8-bit UART realization on [Verilog HDL](https://en.wikipedia.org/wiki/Verilog).

Able to operate 8 bits of serial data, one start bit, one stop bit.

Usage
-----
![uart](rsc/uart.png)

### Parameters:
* `CLOCK_RATE` - board internal clock rate
* `BAUD_RATE` - target baud rate

### IO:

#### control:
* `clk` - **[input]** board internal clock

#### rx interface:
* `rx` - **[input]** receiver input
* `rxEn` - **[input]** enable/disable receiver
* `out[7..0]` - **[output]** received data
* `rxDone` - **[output]** end of transaction (1 posedge clk)
* `rxBusy` - **[output]** transaction is in progress
* `rxErr` - **[output]** transaction error: invalid start/stop bit (1 posedge clk)

#### tx interface:
* `txEn` - **[input]** enable/disable transmitter
* `txStart` - **[input]** start of transaction (1 posedge clk)
* `in[7..0]` - **[input]** data to transmit (stored inside while transaction is in progress)
* `tx` - **[output]** transmitter output
* `txDone` - **[output]** end of transaction (1 posedge clk)
* `txBusy` - **[output]** transaction is in progress



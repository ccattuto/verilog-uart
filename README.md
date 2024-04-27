verilog-uart
============
Simple 8-bit UART implementation in [Verilog HDL](https://en.wikipedia.org/wiki/Verilog).

This is a fork of [verilog-uart](https://github.com/hell03end/verilog-uart). It fixes several issues with the transmit and receive code and adds majority voting for bit sampling. It was synthesized using [Yosys](https://github.com/YosysHQ/yosys) and successfully tested on an FPGA (up to 115200 baud driven by a 48 MHz clock, both transmit and receive.)

It assumes 8 data bits, 1 start bit, 1 stop bit, and no parity. The receiver uses 16x oversampling and majority voting over 3 samples.

Usage
-----

### Parameters:
* `CLOCK_RATE` - clock rate
* `BAUD_RATE` - target baud rate

### IO:

#### control:
* `clk` - **[input]** clock signal

#### rx interface:
* `rx` - **[input]** RX line
* `rxEn` - **[input]** enable/disable receiver
* `out[7..0]` - **[output]** received data
* `rxValid` - **[output]** end of transaction (1 posedge clk)
* `rxReady` - **[output]** low when RX is in progress
* `rxErr` - **[output]** transaction error: invalid start/stop bit (1 posedge clk)

#### tx interface:
* `txEn` - **[input]** enable/disable transmitter
* `txValid` - **[input]** start of transaction (1 posedge clk)
* `in[7..0]` - **[input]** data to transmit (stored inside while transaction is in progress)
* `tx` - **[output]** TX line
* `txReady` - **[output]** low when TX is in progress



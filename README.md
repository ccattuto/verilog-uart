verilog-uart
============
Simple 8-bit UART implementation in [Verilog HDL](https://en.wikipedia.org/wiki/Verilog).

This is originally based on [verilog-uart](https://github.com/hell03end/verilog-uart), which doesn't work. It fixes several issues with the transmit and receive code, adds majority voting for bit sampling, and introduces valid/ready signals for control. It was synthesized using [Yosys](https://github.com/YosysHQ/yosys) and successfully tested on an FPGA (up to 115200 baud driven by a 48 MHz clock, both transmit and receive.)

It assumes 8 data bits, 1 start bit, 1 stop bit, and no parity. The receiver uses 16x oversampling and majority voting over 3 consecutive samples. The transmit and receive modules are separate and can be used independently. 


## UART Transmitter

### Parameters
* `CLOCK_RATE` - clock rate (default 50 MHz)
* `BAUD_RATE` - target baud rate (default 115200 baud)

### Interface
* `clk`  [input wire] - clock (gets divided internally for baud generation)
* `reset` [intput wire] - reset signal
* `enable` [input wire] - enable signal
* `valid` [input wire] - starts TX when held high for 1 clock cycle
* `in` [input wires, 8-bit wide] - byte to transmit, latched internally when `valid` goes high
* `out` [output register] - UART TX signal
* `ready` [output register] - high when the module is ready to transmit a new byte

### Notes
* 8N1 only (8-bit data word, 1 start bit, 1 stop bit)
* internal baud rate generation
* `ready` goes high when the transmitter is ready to send
* to start TX, the user drives `valid` high for 1 clock cycle 


## UART Receiver

### Parameters
* `CLOCK_RATE` - clock rate (default 50 MHz)
* `BAUD_RATE` - target baud rate (default 115200 baud)

### Interface
* `clk` [input wire] - clock (gets divided internally for baud generation)
* `reset` [intput wire] - reset signal
* `enable` [input wire] - enable signal
* `in` [input wire] - UART RX signal
* `ready` [input wire] - driven high to signal that the received byte in `out` was processed and a new RX transaction can begin
* `out` [output 8-bit register] - received byte
* `valid` [output register] - goes high when `out` contains a received byte
* `error` [output register] - high when a frame error occurred
* `overrun` [output register] - high when RX overrun occurred

### Notes
* 8N1 only (8-bit data word, 1 start bit, 1 stop bit)
* `valid` goes high after successful RX and stays high for at least 1 clock cycle
* `valid` is cleared as soon as a high `ready` is detected
* internal baud rate generation
* 16x baud rate oversampling, majority voting over 3 samples for bit sensing
* double-buffered read: a new RX can start before the last received byte has been read

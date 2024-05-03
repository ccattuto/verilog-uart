# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
SRC = ../uart

VERILOG_SOURCES += $(SRC)/UARTTransmitter.v $(SRC)/UARTReceiver.v tb.v

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = test_uart

# MODULE is the basename of the Python test file
MODULE = test_uart

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim


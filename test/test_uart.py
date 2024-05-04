# test_uart.py

import cocotb
from cocotb.triggers import Edge, Timer
from cocotb.clock import Clock
import random


@cocotb.test(timeout_time=50, timeout_unit='ms')
async def transmit(dut):
    """TX with randomized payload / clock frequency shift / inter-TX delay."""

    # 50 Mhz clock
    cocotb.start_soon(Clock(dut.clk, 20, units='ns').start())

    await check_tx_reset(dut)

    # carry out 100 transmissions
    for count in range(100):
        # randomized payload
        TEST_BYTE = random.randint(0,255)

        # randomized baud multiplier (+/- 2%)
        baud_mult = 1.0 + (random.random() - 0.5) / 50 * 2

        await check_tx(dut, TEST_BYTE, 115200, baud_mult)

        # randomized inter-TX interval
        if random.random() > 0.1:
            await Timer(random.randint(1,2000), units='ns')


@cocotb.test(timeout_time=50, timeout_unit='ms')
async def receive1(dut):
    """RX with randomized payload / clock frequency shift / inter-TX delay."""

    # 50 Mhz clock
    cocotb.start_soon(Clock(dut.clk, 20, units='ns').start())

    # reset
    await check_rx_reset(dut)

    # run 100 randomized tests
    for count in range(100):
        # randomized payload
        TEST_BYTE = random.randint(0,255)

        # randomized baud multiplier (+/- 2%)
        baud_mult = 1.0 + (random.random() - 0.5) / 50 * 2

        await check_rx(dut, TEST_BYTE, 115200, baud_mult)

        # randomized delay
        await Timer(random.randint(500,2000), units='ns')


@cocotb.test(timeout_time=50, timeout_unit='ms')
async def receive2(dut):
    """Continuous RX with randomized payload."""

    # 50 Mhz clock
    cocotb.start_soon(Clock(dut.clk, 20, units='ns').start())

    # reset
    await check_tx_reset(dut)

    # run 100 randomized tests
    for count in range(100):
        # randomized payload
        TEST_BYTE = random.randint(0,255)
        await check_rx(dut, TEST_BYTE, 115200, 1.0)


@cocotb.test(timeout_time=50, timeout_unit='ms')
async def receive3(dut):
    """Continuous RX with randomized payload / clock frequency shift."""

    # 50 Mhz clock
    cocotb.start_soon(Clock(dut.clk, 20, units='ns').start())

    # reset
    await check_tx_reset(dut)

    # run 100 randomized tests
    for count in range(100):
        # randomized payload
        TEST_BYTE = random.randint(0,255)

        # randomized baud multiplier (+/- 2%)
        baud_mult = 1.0 + (random.random() - 0.5) / 50 * 2

        await check_rx(dut, TEST_BYTE, 115200, baud_mult)


@cocotb.test(timeout_time=50, timeout_unit='ms')
async def receive4(dut):
    """RX overrun."""

    # 50 Mhz clock
    cocotb.start_soon(Clock(dut.clk, 20, units='ns').start())

    # reset
    await check_tx_reset(dut)

    # set RX ready low, and keep it low...
    dut.rx_ready.value = 0

    # ...across 2 RX operations, until the received overruns
    for count in range(2):
        # prepare random test data
        TEST_BYTE = random.randint(0,255)
        TEST_BITS_LSB = [(TEST_BYTE >> s) & 1 for s in range(8)]

        # send start bit (0), 8 data bits, stop bit (1)
        for tx_bit in [0] + TEST_BITS_LSB + [1]:
            dut.uart_rx.value = tx_bit
            await Timer(int(1 / 115200. * 1e12), units="ps")

        # check payload and valid/error/overflow flags
        assert dut.rx_valid.value == 1
        assert dut.rx_error.value == 0
        if (count == 0):
            TEST_BYTE_PREV = TEST_BYTE
            assert dut.rx_data.value == TEST_BYTE
            assert dut.rx_overrun.value == 0
        else:
            assert dut.rx_data.value == TEST_BYTE_PREV
            assert dut.rx_overrun.value == 1



# --- HELPER FUNCTIONS ---

async def check_tx_reset(dut):
    # reset
    dut.tx_reset.value = 1
    await Timer(1, units="ms")
    dut.tx_reset.value = 0
    await Timer(1, units="ms")

    assert dut.tx_ready.value == 1


async def check_rx_reset(dut):
    # drive input high
    dut.uart_rx.value = 1

    # reset
    dut.rx_reset.value = 1
    await Timer(1, units="ms")
    dut.rx_reset.value = 0
    await Timer(1, units="ms")

    assert dut.rx_valid.value == 0
    assert dut.rx_error.value == 0
    assert dut.rx_overrun.value == 0


async def check_tx(dut, data, baud, baud_mult):
    # check TX=1 and ready=1
    assert dut.uart_tx == 1
    assert dut.tx_ready.value == 1

    # prepare random test data
    TEST_BITS_LSB = [(data >> s) & 1 for s in range(8)]

    # set data value and then start TX
    dut.tx_data.value = data
    await Timer(random.randint(100, 500), units="ns")
    dut.tx_valid.value = 1

    # wait for TX->0 transition, check TX=0 and ready=0
    await Edge(dut.uart_tx)
    assert dut.uart_tx.value == 0
    assert dut.tx_ready.value == 0

    # set valid back to 0
    dut.tx_valid.value = 0

    # wait 1/2 bit
    await Timer(int(0.5 / baud * baud_mult * 1e12), units="ps")

    # check for start bit (0), 8 data bits, stop bit (1)
    for expected_bit in [0] + TEST_BITS_LSB + [1]:
        assert dut.uart_tx.value == expected_bit
        await Timer(int(1.0 / baud * baud_mult * 1e12), units="ps")

    assert dut.tx_ready.value == 1


async def check_rx(dut, data, baud, baud_mult):
    dut.rx_ready.value = 0

    # random delay
    await Timer(100 + random.randint(100, 500), units="ns")
    assert dut.rx_valid.value == 0

    # prepare random test data
    TEST_BITS_LSB = [(data >> s) & 1 for s in range(8)]

    # send start bit (0), 8 data bits, stop bit (1)
    for tx_bit in [0] + TEST_BITS_LSB + [1]:
        dut.uart_rx.value = tx_bit
        await Timer(int(1 / baud * baud_mult * 1e12), units="ps")

    # random delay
    await Timer(100 + random.randint(100, 500), units="ns")
    assert dut.rx_valid.value == 1

    dut.rx_ready.value = 1

    # wait for valid transition
    await Edge(dut.rx_valid)
    assert dut.rx_valid.value == 0

    # check payload and valid/error/overflow flags
    assert dut.rx_data.value == data
    assert dut.rx_error.value == 0
    assert dut.rx_overrun.value == 0


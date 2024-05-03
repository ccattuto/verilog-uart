# test_uart.py

import cocotb
from cocotb.triggers import Edge, Timer
from cocotb.clock import Clock
import random


@cocotb.test(timeout_time=50, timeout_unit='ms')
async def transmit(dut):
    """TX with randomized payload, clock skew, inter-TX delay."""

    # 25 Mhz clock
    cocotb.start_soon(Clock(dut.clk, 40, units='ns').start())

    # reset
    dut.tx_reset.value = 1
    await Timer(1, units="ms")
    dut.tx_reset.value = 0
    await Timer(1, units="ms")

    # run 100 randomized tests
    for count in range(100):
        # check TX=1 and ready=1
        assert dut.uart_tx == 1
        assert dut.tx_ready.value == 1

        # prepare random test data
        TEST_BYTE = random.randint(0,255) # 0xA5
        TEST_BITS_LSB = [(TEST_BYTE >> s) & 1 for s in range(8)]

        # set data value and then start TX
        dut.tx_data.value = TEST_BYTE
        await Timer(100 + random.randint(0, 1000), units="ns")
        dut.tx_valid.value = 1

        # wait for TX->0 transition, check TX=0 and ready=0
        await Edge(dut.uart_tx)
        assert dut.uart_tx.value == 0
        assert dut.tx_ready.value == 0

        # set valid back to 0
        dut.tx_valid.value = 0

        # randomized RX frequency skew (+/- 1%)
        skew = 1.0 + (random.random() - 0.5) / 50 * 1

        # wait 1/2 bit
        await Timer(int(0.5 / 115200. * skew * 1e12), units="ps")

        # check for start bit (0), 8 data bits, stop bit (1)
        for expected_bit in [0] + TEST_BITS_LSB + [1]:
            assert dut.uart_tx.value == expected_bit
            await Timer(int(1 / 115200. * skew * 1e12), units="ps")

        assert dut.tx_ready.value == 1

        # randomized inter-TX interval
        if random.random() > 0.2:
            await Timer(random.randint(1,10), units='us')



@cocotb.test(timeout_time=50, timeout_unit='ms')
async def receive(dut):
    """RX with randomized payload."""

    # ~24 Mhz clock
    cocotb.start_soon(Clock(dut.clk, 42, units='ns').start())

    # drive input high
    dut.uart_rx.value = 1

    # reset
    dut.rx_reset.value = 1
    await Timer(1, units="ms")
    dut.rx_reset.value = 0
    await Timer(1, units="ms")

    # check valid=0, err=0
    assert dut.rx_valid.value == 0
    assert dut.rx_err.value == 0

    # check internal state of receiver
    assert dut.uart_receiver.clockCount == 0
    assert dut.uart_receiver.bitIndex == 0
    assert dut.uart_receiver.inputReg == 7

    # random delay
    await Timer(100 + random.randint(0, 1000), units="ns")
    assert dut.rx_valid.value == 0
    
    # run 100 randomized tests
    for count in range(100):
        dut.rx_ready.value = 0

        # # random delay
        # await Timer(100 + random.randint(0, 1000), units="ns")
        # assert dut.rx_valid.value == 0

        # prepare random test data
        TEST_BYTE = random.randint(0,255) # 0xA5
        TEST_BITS_LSB = [(TEST_BYTE >> s) & 1 for s in range(8)]

        # send start bit (0), 8 data bits, stop bit (1)
        for tx_bit in [0] + TEST_BITS_LSB + [1]:
            dut.uart_rx.value = tx_bit
            await Timer(int(1 / 115200. * 1e12), units="ps")
            #dut.uart_receiver.bitIndex._log.info(f"bitIndex={dut.uart_receiver.bitIndex.value}")
            #dut.uart_receiver.inputReg._log.info(f"inputReg={dut.uart_receiver.inputReg.value}")
            #dut.uart_receiver.clockCount._log.info(f"clockCount={dut.uart_receiver.clockCount.value}")
            #dut.uart_receiver.data._log.info(f"data={dut.uart_receiver.data.value}")
            #dut.uart_receiver.state._log.info(f"state={dut.uart_receiver.state.value}")

        # random delay
        #await Timer(100 + random.randint(0, 1000), units="ns")
    
        dut.rx_ready.value = 1

        # wait for valid transition, check that valid=1 and payload is correct
        await Edge(dut.rx_valid)
        #dut.uart_receiver.state._log.info(f"state={dut.uart_receiver.state.value}")
        #assert dut.uart_receiver.state == 2
        #dut.rx_err._log.info(f"rx_err={dut.rx_err.value}")
        #dut.rx_valid._log.info(f"rx_valid={dut.rx_valid.value}")
        #dut.uart_receiver.data._log.info(f"data={dut.uart_receiver.data.value}")
        #dut.uart_receiver.out._log.info(f"out={dut.uart_receiver.out.value}")
        #dut.rx_overrun._log.info(f"overrun={dut.rx_overrun.value}")

        assert dut.rx_data.value == TEST_BYTE

        # randomized delay
        #if random.random() > 0.2:
        #    await Timer(random.randint(1,10), units='us')


//
// UART Transmitter
// 
//
//

 // states of state machine
`define IDLE        3'b010
`define START_BIT   3'b011
`define DATA_BITS   3'b100
`define WAIT_STOP   3'b101
`define STOP_BIT    3'b110

module UARTTransmitter #(
    parameter CLOCK_RATE = 50000000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,      // clock
    input  wire       reset,    // reset
    input  wire       en,       // TX enable
    input  wire       valid,    // start transaction
    input  wire [7:0] in,       // data to transmit
    output reg        out,      // TX line
    output reg        ready     // ready for TX
);
    parameter MAX_RATE_TX = CLOCK_RATE / BAUD_RATE;
    parameter TX_CNT_WIDTH = $clog2(MAX_RATE_TX);
    reg [TX_CNT_WIDTH - 1:0] txCounter = 0;
    
    reg [2:0] state = `IDLE;
    reg [7:0] data = 8'b0; // to store a copy of input data
    reg [2:0] bitIdx = 3'b0; // for 8-bit data

    initial begin
        ready <= 0;
    end

    always @(posedge clk) begin
        if (reset) begin
            ready <= 0;
            out <= 1; 
            bitIdx <= 3'b0;
            data <= 8'b0;
            state <= `IDLE;
            txCounter <= 0;
        end else if (en & ready & valid) begin
            data    <= in; // latch input data
            ready   <= 1'b0;
            state   <= `START_BIT;
        end else if (txCounter < MAX_RATE_TX - 1) begin
            // TX clock
            txCounter <= txCounter + 1;
        end else begin
            txCounter <= 0;
            case (state)
                default: begin
                    state <= `IDLE;
                end
                
                `IDLE: begin
                    out <= 1; // drive line high
                    ready <= 1;
                    bitIdx <= 3'b0;
                    data <= 8'b0;
                end

                `START_BIT: begin
                    out <= 0; // send start bit (low)
                    state <= `DATA_BITS;
                end

                `DATA_BITS: begin // Wait 8 clock cycles for data bits to be sent
                    out <= data[bitIdx];
                    if (&bitIdx) begin
                        bitIdx <= 3'b0;
                        state <= `STOP_BIT;
                    end else begin
                        bitIdx <= bitIdx + 1;
                    end
                end

                `STOP_BIT: begin // Send out Stop bit (high)
                    out <= 1;
                    state <= `IDLE;
                end
            endcase
        end
    end

endmodule

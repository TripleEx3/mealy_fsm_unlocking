`timescale 1ns/1ps

module mealy_unlock_fsm_tb();
    // Parameters
    parameter CLOCK_PERIOD = 10; // 10ns = 100MHz clock
    
    // Test bench signals
    logic clk;
    logic reset;
    logic serial_ready;
    logic serial_valid;
    logic serial_data;
    logic unlock;
    logic pwd_incorrect;
    
    // Instantiate the Unit Under Test (UUT)
    mealy_fsm_unlocking uut (
        .clk(clk),
        .reset(reset),
        .serial_ready(serial_ready),
        .serial_valid(serial_valid),
        .serial_data(serial_data),
        .unlock(unlock),
        .pwd_incorrect(pwd_incorrect)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end
    
    // State monitoring for debug
    string state_string;
    always_comb begin
        case (uut.current_state)
            uut.IDLE: state_string = "IDLE";
            uut.S_1:  state_string = "S_1";
            uut.S_10: state_string = "S_10";
            uut.S_101: state_string = "S_101";
            default:  state_string = "UNKNOWN";
        endcase
    end
    
    // Test sequence
    initial begin
        // Initialize signals
        reset = 1;
        serial_ready = 1;
        serial_valid = 0;
        serial_data = 0;
        
        // Apply reset
        #(CLOCK_PERIOD*2);
        reset = 0;
        #(CLOCK_PERIOD);
        
        // Test Case 1: Correct unlock sequence "1011"
        $display("Test Case 1: Correct unlock sequence 1011");
        send_bit(1);
        send_bit(0);
        send_bit(1);
        send_bit(1);
        
        // Test Case 2: Incorrect sequence "1001"
        $display("Test Case 2: Incorrect sequence 1001");
        send_bit(1);
        send_bit(0);
        send_bit(0);
        send_bit(1);
        
        // Test Case 3: Partial sequence followed by reset
        $display("Test Case 3: Partial sequence followed by reset");
        send_bit(1);
        send_bit(0);
        reset = 1;
        #(CLOCK_PERIOD*2);
        reset = 0;
        #(CLOCK_PERIOD);
        
        // Test Case 4: Multiple back-to-back correct sequences
        $display("Test Case 4: Multiple back-to-back correct sequences");
        send_bit(1);
        send_bit(0);
        send_bit(1);
        send_bit(1);
        send_bit(1);
        send_bit(0);
        send_bit(1);
        send_bit(1);
        
        // Test Case 5: Incorrect then correct sequence
        $display("Test Case 5: Incorrect then correct sequence");
        send_bit(0); // Should stay in IDLE
        send_bit(1);
        send_bit(0);
        send_bit(1);
        send_bit(1);
        
        // End simulation after some delay
        #(CLOCK_PERIOD*5);
        $display("Simulation complete");
        $stop;
    end
    
    // Task to send a single bit to the FSM
    task send_bit(input logic bit_value);
        serial_valid = 1;
        serial_data = bit_value;
        #(CLOCK_PERIOD);
        
        // Print current state and outputs for debugging
        $display("Time: %0t, Bit: %b, State: %s, Output: %b, OutputValid: %b", 
                 $time, bit_value, state_string, unlock, pwd_incorrect);
        
        serial_valid = 0;
        #(CLOCK_PERIOD);
    endtask
    
    // Add waveform monitoring
    initial begin
        $display("Starting simulation");
        // Uncomment for waveform dumping in Quartus if needed
        // $dumpfile("mealy_unlock_fsm_waves.vcd");
        // $dumpvars(0, mealy_unlock_fsm_tb);
    end

endmodule

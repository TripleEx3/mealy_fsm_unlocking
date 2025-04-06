module mealy_fsm_unlocking (
    input logic clk,
    input logic reset,
    input logic serial_data,
    input logic serial_valid,
    output logic unlock,
    output logic pwd_incorrect,
    output logic serial_ready
);
    
    enum logic [2:0] {
        IDLE  = 3'b000,  // Initial state
        S_1   = 3'b001,  // Got 1
        S_10  = 3'b010,  // Got 10
        S_101 = 3'b011   // Got 101
    } current_state, next_state;
    
    // 1. State Sequencer (Sequential Logic)
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    // 2. Next-State Decoder (Combinational Logic)
    always_comb begin
        next_state = current_state;  // Default: hold state
        
        if (serial_valid) begin
            case (current_state)
                IDLE:  next_state = (serial_data == 1'b1) ? S_1   : IDLE;
                S_1:   next_state = (serial_data == 1'b0) ? S_10  : IDLE;
                S_10:  next_state = (serial_data == 1'b1) ? S_101 : IDLE;
                S_101: next_state = (serial_data == 1'b1) ? IDLE  : IDLE;
                default: next_state = IDLE;
            endcase
        end
    end
    
    // 3. Output Decoder (Combinational Logic)
    always_comb begin
        unlock = 1'b0;
        pwd_incorrect = 1'b0;
        serial_ready = 1'b1;
        
        if (serial_valid) begin
            case (current_state)
                IDLE: begin
                    if (serial_data != 1'b1) begin
                        pwd_incorrect = 1'b1;
                        serial_ready = 1'b0;  // Not ready after error
                    end
                end
                S_1: begin
                    if (serial_data != 1'b0) begin
                        pwd_incorrect = 1'b1;
                        serial_ready = 1'b0;  // Not ready after error
                    end
                end
                S_10: begin
                    if (serial_data != 1'b1) begin
                        pwd_incorrect = 1'b1;
                        serial_ready = 1'b0;  // Not ready after error
                    end
                end
                S_101: begin
                    if (serial_data == 1'b1) begin
                        unlock = 1'b1;
                        serial_ready = 1'b0;  // Not ready after unlock
                    end
                    else begin
                        pwd_incorrect = 1'b1;
                        serial_ready = 1'b0;  // Not ready after error
                    end
                end
                default: begin
                    unlock = 1'b0;
                    pwd_incorrect = 1'b0;
                end
            endcase
        end
    end
endmodule

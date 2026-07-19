module ps2_receiver (
    input  wire clk,           // System clock (50MHz, DE1-SoC onboard)
    input  wire reset_n,       // Active-low reset
    input  wire ps2_clk,       // Raw PS2 clock line from keyboard
    input  wire ps2_dat,       // Raw PS2 data line from keyboard
    output reg  [7:0] scan_code,  // Decoded 8-bit scan code
    output reg  data_ready     // Pulses HIGH for 1 clock cycle when new scan_code is ready
);
    // ============================================
    // Step A: Synchronize PS2_CLK and PS2_DAT
    // (double-flop synchronizer to avoid metastability)
    // ============================================
    reg ps2_clk_sync1, ps2_clk_sync2;
    reg ps2_dat_sync1, ps2_dat_sync2;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ps2_clk_sync1 <= 1'b1;
            ps2_clk_sync2 <= 1'b1;
            ps2_dat_sync1 <= 1'b1;
            ps2_dat_sync2 <= 1'b1;
        end
        else begin
            ps2_clk_sync1 <= ps2_clk;
            ps2_clk_sync2 <= ps2_clk_sync1;
            ps2_dat_sync1 <= ps2_dat;
            ps2_dat_sync2 <= ps2_dat_sync1;
        end
    end
    // ============================================
    // Step B: Detect Falling Edge of PS2_CLK
    // (data is valid/stable on falling edge)
    // ============================================
    reg ps2_clk_prev;
    wire falling_edge;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            ps2_clk_prev <= 1'b1;
        else
            ps2_clk_prev <= ps2_clk_sync2;
    end
    assign falling_edge = ps2_clk_prev & ~ps2_clk_sync2;  // 1 -> 0 transition
    // ============================================
    // Step C: Shift In 11 Bits (start + 8 data + parity + stop)
    // ============================================
    reg [10:0] shift_reg;
    reg [3:0]  bit_count;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg  <= 11'b0;
            bit_count  <= 4'd0;
            data_ready <= 1'b0;
            scan_code  <= 8'b0;
        end
        else begin
            data_ready <= 1'b0;  // default: stays low unless we just completed a packet
            if (falling_edge) begin
                // Shift new bit into register (MSB side, since data comes LSB-first
                // and we want bit[0] to end up holding the very first bit received)
                shift_reg <= {ps2_dat_sync2, shift_reg[10:1]};
                bit_count <= bit_count + 1'b1;
                if (bit_count == 4'd10) begin
                    // 11 bits received: at THIS falling edge (the stop bit is
                    // arriving right now), shift_reg still holds the state from
                    // AFTER the previous edge (10 bits received: start,D0..D7,parity).
                    // At that point D7..D0 sit at shift_reg[9:2], NOT [8:1].
                    scan_code  <= shift_reg[9:2];  // extract 8 data bits (FIXED)
                    data_ready <= 1'b1;            // pulse for 1 cycle
                    bit_count  <= 4'd0;
                end
            end
        end
    end
endmodule
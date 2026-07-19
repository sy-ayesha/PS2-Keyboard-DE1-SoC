module PS2_top (
    input  wire CLOCK_50,      // DE1-SoC onboard 50MHz clock
    input  wire [3:0] KEY,     // Push buttons (KEY[0] = reset)
    inout  wire PS2_CLK,       // PS2 clock line (bidirectional in real hardware)
    inout  wire PS2_DAT,       // PS2 data line (bidirectional in real hardware)
    output wire [9:0] LEDR,    // LEDs
    output wire [6:0] HEX0,    // 7-segment: lower nibble of scan code
    output wire [6:0] HEX1     // 7-segment: upper nibble of scan code
);
    wire reset_n;
    assign reset_n = KEY[0];
    // ============================================
    // PS2 Receiver Instantiation
    // ============================================
    wire [7:0] scan_code;
    wire data_ready;
    ps2_receiver u_ps2_receiver (
        .clk        (CLOCK_50),
        .reset_n    (reset_n),
        .ps2_clk    (PS2_CLK),
        .ps2_dat    (PS2_DAT),
        .scan_code  (scan_code),
        .data_ready (data_ready)
    );
    // ============================================
    // Latch the scan code (hold value until next key press)
    // ============================================
    reg [7:0] scan_code_latched;
    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n)
            scan_code_latched <= 8'h00;
        else if (data_ready)
            scan_code_latched <= scan_code;
    end
    // ============================================
    // Split into two nibbles for two 7-segment displays
    // ============================================
    wire [3:0] upper_nibble;
    wire [3:0] lower_nibble;
    assign upper_nibble = scan_code_latched[7:4];
    assign lower_nibble = scan_code_latched[3:0];
    hex_to_7seg u_hex0 (
        .hex_in  (lower_nibble),
        .seg_out (HEX0)
    );
    hex_to_7seg u_hex1 (
        .hex_in  (upper_nibble),
        .seg_out (HEX1)
    );
    // ============================================
    // LED indicator: blink/toggle every time a new scan code arrives
    // (helps visually confirm data is being received)
    // ============================================
    reg activity_led;
    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n)
            activity_led <= 1'b0;
        else if (data_ready)
            activity_led <= ~activity_led;
    end
    assign LEDR[0] = activity_led;
    assign LEDR[9:1] = 9'b0;
endmodule

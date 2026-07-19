`timescale 1ns/1ps

module tb_ps2_receiver;

    reg clk;
    reg reset_n;
    reg ps2_clk;
    reg ps2_dat;
    wire [7:0] scan_code;
    wire data_ready;

    ps2_receiver DUT (
        .clk        (clk),
        .reset_n    (reset_n),
        .ps2_clk    (ps2_clk),
        .ps2_dat    (ps2_dat),
        .scan_code  (scan_code),
        .data_ready (data_ready)
    );

    always #10 clk = ~clk;

    task send_bit(input b);
        begin
            ps2_dat = b;
            #250;
            ps2_clk = 0;
            #500;
            ps2_clk = 1;
            #250;
        end
    endtask

    task send_scan_code(input [7:0] code);
        integer i;
        reg parity;
        begin
            parity = ~^code;
            send_bit(1'b0);
            for (i = 0; i < 8; i = i + 1)
                send_bit(code[i]);
            send_bit(parity);
            send_bit(1'b1);
        end
    endtask

    initial begin
        clk     = 0;
        reset_n = 0;
        ps2_clk = 1;
        ps2_dat = 1;

        #100;
        reset_n = 1;
        #100;

        send_scan_code(8'h1C);
        #2000;

        send_scan_code(8'h32);
        #2000;

        send_scan_code(8'h16);
        #2000;

        $stop;
    end

    initial begin
        $monitor("time=%0t reset_n=%b ps2_clk=%b ps2_dat=%b data_ready=%b scan_code=%h",
                  $time, reset_n, ps2_clk, ps2_dat, data_ready, scan_code);
    end

endmodule

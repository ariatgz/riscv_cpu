`timescale 1ns / 1ps

module tb_system;
    logic sys_clk_p;
    logic sys_clk_n;
    logic rst_n;
    logic uart_tx_out;

    // Instantiate the top-level wrapper
    rv32_system u_dut (
        .sys_clk_p   (sys_clk_p),
        .sys_clk_n   (sys_clk_n),
        .rst_n       (rst_n),
        .uart_tx_out (uart_tx_out)
    );

    // Generate 200MHz Differential Clock (5ns total period)
    initial begin
        sys_clk_p = 1'b0;
        sys_clk_n = 1'b1;
        forever begin
            #2.5; 
            sys_clk_p = ~sys_clk_p;
            sys_clk_n = ~sys_clk_n;
        end
    end

    // Reset Sequence
    initial begin
        rst_n = 1'b0;
        #15;
        rst_n = 1'b1;
        
        // Run for 150 microseconds (long enough to transmit one 115200 baud byte)
        #150000; 
        $finish;
    end
endmodule
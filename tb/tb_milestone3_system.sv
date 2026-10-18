`timescale 1ns / 1ps
`timescale 1ns / 1ps

module tb_milestone3_system;
    logic clk = 0;
    logic rst_n;
    
    // CPU <-> Memory Bus
    logic [31:0] imem_addr, imem_rdata;
    logic        dmem_wr;
    logic [3:0]  dmem_we;
    logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;

    always #5 clk = ~clk;

    // The CPU
    rv32_core u_core (
        .clk        (clk),
        .rst_n      (rst_n),
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),
        .dmem_wr    (dmem_wr),
        .dmem_we    (dmem_we),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_rdata (dmem_rdata)
    );

    // The Memory (Ensure "program.mem" is in your Vivado simulation directory)
    rv32_memory #(
        .INIT_FILE ("program.mem")
    ) u_mem (
        .clk        (clk),
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),
        .dmem_wr    (dmem_wr),
        .dmem_we    (dmem_we),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_rdata (dmem_rdata)
    );

    initial begin
        $display("=== Booting RISC-V System ===");
        rst_n = 0;
        #15;
        rst_n = 1;

        // Run for 200 cycles to let Fibonacci finish
        repeat (200) @(posedge clk);
        
        $display("=== Simulation Finished ===");
        $finish;
    end
endmodule

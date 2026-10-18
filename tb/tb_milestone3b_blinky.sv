`timescale 1ns / 1ps

module tb_milestone3b_blinky;

    logic        clk = 0;
    logic        rst_n;
    
    // Core memory interfaces
    logic [31:0] imem_addr, imem_rdata;
    logic        dmem_wr;
    logic [3:0]  dmem_we;
    logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;

    // Generate 100MHz clock
    always #5 clk = ~clk;

    // Instantiate your CPU!
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

    // Dummy Data Memory (we aren't using it for Blinky, but tie it off)
    assign dmem_rdata = 32'd0;

    // Simulated ROM: The "Blinky" Infinite Loop
    always_comb begin
        // Imem_addr is byte-addressed, so we divide by 4 to get the word index [31:2]
        case (imem_addr[31:2])
            // 0: addi x10, x0, 0
            0: imem_rdata = 32'h0000_0513; 
            
            // 1: addi x10, x10, 1
            1: imem_rdata = 32'h0015_0513; 
            
            // 2: jal x0, -4 (Jump back 4 bytes to instruction 1)
            2: imem_rdata = 32'hFFDF_F06F; 
            
            // Default: NOP (addi x0, x0, 0)
            default: imem_rdata = 32'h0000_0013;
        endcase
    end

    initial begin
        $display("=== Booting RISC-V Blinky CPU ===");
        rst_n = 0;
        
        // Hold reset for 2 clock cycles
        @(posedge clk);
        @(posedge clk);
        rst_n = 1;

        // Let the CPU run for 20 clock cycles (x10 should count up to ~8)
        repeat (20) @(posedge clk);

        $display("=== Simulation Complete. Open Waveform Viewer! ===");
        $finish;
    end
endmodule
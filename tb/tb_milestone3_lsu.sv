`timescale 1ns / 1ps

module tb_milestone3_lsu;

    logic [2:0]  funct3;
    logic        mem_wr;
    logic [1:0]  addr_offset;
    logic [31:0] rs2_data;
    logic [3:0]  dmem_we;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_rdata;
    logic [31:0] lsu_rdata;

    rv32_lsu u_lsu (
        .funct3      (funct3),
        .mem_wr      (mem_wr),
        .addr_offset (addr_offset),
        .rs2_data    (rs2_data),
        .dmem_we     (dmem_we),
        .dmem_wdata  (dmem_wdata),
        .dmem_rdata  (dmem_rdata),
        .lsu_rdata   (lsu_rdata)
    );

    initial begin
        $display("=== Starting Milestone 3A (LSU) Verification ===");

        // -----------------------------------------------------------------
        // 1. Test Store Byte (SB) at offset 2 (2'b10)
        // -----------------------------------------------------------------
        mem_wr      = 1'b1;
        funct3      = 3'b000; // SB
        addr_offset = 2'b10;  // Byte lane 2 ([23:16])
        rs2_data    = 32'hDEAD_BE5A;
        #1;
        assert (dmem_we == 4'b0100 && dmem_wdata[23:16] == 8'h5A)
            else $fatal(1, "FAIL: SB at offset 2! we=%b, wdata=%h", dmem_we, dmem_wdata);
        $display("[PASS] SB at offset 2: dmem_we=%b, byte lane 2=%h", dmem_we, dmem_wdata[23:16]);

        // -----------------------------------------------------------------
        // 2. Test Store Halfword (SH) at offset 2 (2'b10)
        // -----------------------------------------------------------------
        funct3      = 3'b001; // SH
        addr_offset = 2'b10;  // Upper halfword ([31:16])
        rs2_data    = 32'h0000_CAFE;
        #1;
        assert (dmem_we == 4'b1100 && dmem_wdata[31:16] == 16'hCAFE)
            else $fatal(1, "FAIL: SH at offset 2! we=%b, wdata=%h", dmem_we, dmem_wdata);
        $display("[PASS] SH at offset 2: dmem_we=%b, upper half=%h", dmem_we, dmem_wdata[31:16]);

        // -----------------------------------------------------------------
        // 3. Test mem_wr = 0 (Loads must NEVER assert dmem_we!)
        // -----------------------------------------------------------------
        mem_wr      = 1'b0;
        #1;
        assert (dmem_we == 4'b0000)
            else $fatal(1, "FAIL: dmem_we is non-zero (%b) when mem_wr=0!", dmem_we);
        $display("[PASS] dmem_we safely 4'b0000 when mem_wr=0");

        // -----------------------------------------------------------------
        // 4. Test Signed vs Unsigned Load Byte (LB vs LBU)
        // -----------------------------------------------------------------
        dmem_rdata  = 32'h80F0_7F85; // Byte 3=0x80, Byte 2=0xF0, Byte 1=0x7F, Byte 0=0x85
        addr_offset = 2'b10;         // Select Byte 2 (0xF0 -> negative in signed 8-bit!)
        
        // 4a: LB (Signed) -> Expect 0xFFFF_FFF0
        funct3 = 3'b000;
        #1;
        assert (lsu_rdata == 32'hFFFF_FFF0)
            else $fatal(1, "FAIL: LB sign-extension failed! Got %h, expected FFFFFFF0", lsu_rdata);
        $display("[PASS] LB (Signed) at offset 2: 0xF0 -> %h", lsu_rdata);

        // 4b: LBU (Unsigned) -> Expect 0x0000_00F0
        funct3 = 3'b100;
        #1;
        assert (lsu_rdata == 32'h0000_00F0)
            else $fatal(1, "FAIL: LBU zero-extension failed! Got %h, expected 000000F0", lsu_rdata);
        $display("[PASS] LBU (Unsigned) at offset 2: 0xF0 -> %h", lsu_rdata);

        // -----------------------------------------------------------------
        // 5. Test Signed Load Halfword (LH) at offset 2
        // -----------------------------------------------------------------
        // Upper halfword is 0x80F0 (negative!) -> Expect 0xFFFF_80F0
        funct3      = 3'b001; // LH
        addr_offset = 2'b10;
        #1;
        assert (lsu_rdata == 32'hFFFF_80F0)
            else $fatal(1, "FAIL: LH sign-extension failed! Got %h, expected FFFF80F0", lsu_rdata);
        $display("[PASS] LH (Signed) at offset 2: 0x80F0 -> %h", lsu_rdata);

        $display("=== ALL MILESTONE 3A (LSU) TESTS PASSED! ===");
        $finish;
    end
endmodule
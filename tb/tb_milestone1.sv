`timescale 1ns / 1ps

module tb_milestone1;
    import rv32_pkg::*;

    // Clock generation (100 MHz -> 10ns period)
    logic clk = 0;
    always #5 clk = ~clk;

    // Regfile signals
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    logic [31:0] rs1_data, rs2_data, rd_data;
    logic        wr_en;

    // ImmGen signals
    logic [31:0] instr;
    imm_src_e    imm_src;
    logic [31:0] imm_ext;

    // Instantiate DUTs (Devices Under Test)
    rv32_regfile u_regfile (
        .clk      (clk),
        .rs1_addr (rs1_addr),
        .rs1_data (rs1_data),
        .rs2_addr (rs2_addr),
        .rs2_data (rs2_data),
        .wr_en    (wr_en),
        .rd_addr  (rd_addr),
        .rd_data  (rd_data)
    );

    rv32_imm_gen u_imm_gen (
        .instr_imm_bits (instr[31:7]),
        .imm_src        (imm_src),
        .imm_ext        (imm_ext)
    );

    initial begin
        $display("=== Starting Milestone 1 Verification ===");
        wr_en = 0; rs1_addr = 0; rs2_addr = 0; rd_addr = 0; rd_data = 0;
        instr = 0; imm_src = IMM_I;
        @(posedge clk);

        // -----------------------------------------------------------------
        // Test 1: Register x0 Hardwiring
        // -----------------------------------------------------------------
        wr_en   = 1'b1;
        rd_addr = 5'd0;          // Attempt to overwrite x0!
        rd_data = 32'hDEAD_BEEF;
        @(posedge clk);
        #1; // Wait 1ns after clock edge for combinational read
        rs1_addr = 5'd0;
        #1;
        assert (rs1_data == 32'h0000_0000)
            else $fatal(1, "FAIL: x0 was overwritten with %h!", rs1_data);
        $display("[PASS] x0 ignored write of 0xDEADBEEF and returned 0.");

       // -----------------------------------------------------------------
        // Test 2: Standard Register Write & Dual Asynchronous Read
        // -----------------------------------------------------------------
        wr_en   = 1'b1;
        
        // Drive x5 write data AFTER a clock edge so it's stable
        @(posedge clk);
        #1;
        rd_addr = 5'd5;          // x5 (t0)
        rd_data = 32'h1234_5678;
        
        // Wait for the clock edge that actually performs the write
        @(posedge clk);
        #1;
        
        // Drive x10 write data
        rd_addr = 5'd10;         // x10 (a0)
        rd_data = 32'hCAFE_BABE;
        
        // Wait for the clock edge that writes x10
        @(posedge clk);
        #1;
        
        // Disable write, then read back combinationally
        wr_en    = 1'b0;
        rs1_addr = 5'd5;
        rs2_addr = 5'd10;
        #1;
        
        assert (rs1_data == 32'h1234_5678 && rs2_data == 32'hCAFE_BABE)
            else $fatal(1, "FAIL: Regfile read mismatch! x5=%h, x10=%h", rs1_data, rs2_data);
        $display("[PASS] Dual-port read verified: x5=%h, x10=%h", rs1_data, rs2_data);

        // -----------------------------------------------------------------
        // Test 3: Immediate Generator Sign-Extension & Bit Unscrambling
        // -----------------------------------------------------------------
        // 3a: ADDI x1, x0, -5  (Machine code: 0xFFB00093) -> Expect 0xFFFFFFFB (-5)
        instr   = 32'hFFB0_0093;
        imm_src = IMM_I;
        #1;
        assert (imm_ext == 32'hFFFF_FFFB)
            else $fatal(1, "FAIL: IMM_I expected 0xFFFFFFFB, got %h", imm_ext);
        $display("[PASS] IMM_I (-5): decoded as %h (%0d)", imm_ext, $signed(imm_ext));

        // 3b: BEQ x0, x0, -8   (Machine code: 0xFE000CE3) -> Expect 0xFFFFFFF8 (-8)
        instr   = 32'hFE00_0CE3;
        imm_src = IMM_B;
        #1;
        assert (imm_ext == 32'hFFFF_FFF8)
            else $fatal(1, "FAIL: IMM_B expected 0xFFFFFFF8, got %h", imm_ext);
        $display("[PASS] IMM_B (-8): decoded as %h (%0d)", imm_ext, $signed(imm_ext));

        // 3c: LUI x2, 0x12345  (Machine code: 0x12345137) -> Expect 0x12345000
        instr   = 32'h1234_5137;
        imm_src = IMM_U;
        #1;
        assert (imm_ext == 32'h1234_5000)
            else $fatal(1, "FAIL: IMM_U expected 0x12345000, got %h", imm_ext);
        $display("[PASS] IMM_U (0x12345 << 12): decoded as %h", imm_ext);

        $display("=== ALL MILESTONE 1 TESTS PASSED! ===");
        $finish;
    end
endmodule
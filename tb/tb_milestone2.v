`timescale 1ns / 1ps

module tb_milestone2;
    import rv32_pkg::*;

    // ALU test signals
    logic [31:0] alu_a, alu_b, alu_result;
    alu_op_e     alu_op;
    logic        zero_flag;

    // Branch Comparator test signals
    logic [31:0] bc_rs1, bc_rs2;
    logic [2:0]  bc_funct3;
    logic        branch_taken;

    // Control Unit test signals
    opcode_e     ctrl_opcode;
    logic [2:0]  ctrl_funct3;
    logic        ctrl_funct7_5;
    imm_src_e    ctrl_imm_src;
    logic        ctrl_alu_src;
    alu_op_e     ctrl_alu_op;
    logic        ctrl_mem_wr;
    logic        ctrl_reg_wr;
    logic [1:0]  ctrl_result_src;
    logic        ctrl_branch;
    logic        ctrl_jump;

    // Instantiate ALU DUT
    rv32_alu u_alu (
        .alu_a      (alu_a),
        .alu_b      (alu_b),
        .alu_op     (alu_op),
        .alu_result (alu_result),
        .zero_flag  (zero_flag)
    );

    // Instantiate Branch Comparator DUT
    rv32_branch_comp u_bc (
        .rs1_data     (bc_rs1),
        .rs2_data     (bc_rs2),
        .funct3       (bc_funct3),
        .branch_taken (branch_taken)
    );

    // Instantiate Control Decoder DUT
    rv32_control u_ctrl (
        .opcode       (ctrl_opcode),
        .funct3       (ctrl_funct3),
        .funct7_5     (ctrl_funct7_5),
        .imm_src      (ctrl_imm_src),
        .alu_src      (ctrl_alu_src),
        .alu_op       (ctrl_alu_op),
        .mem_wr       (ctrl_mem_wr),
        .reg_wr       (ctrl_reg_wr),
        .result_src   (ctrl_result_src),
        .branch       (ctrl_branch),
        .jump         (ctrl_jump)
    );

    initial begin
        $display("=== Starting Milestone 2 Verification ===");

        // -----------------------------------------------------------------
        // 1. Test ALU Operations
        // -----------------------------------------------------------------
        // Test ALU_ADD: 15 + 27 = 42
        alu_a = 32'd15; alu_b = 32'd27; alu_op = ALU_ADD;
        #1;
        assert (alu_result == 32'd42 && !zero_flag) 
            else $fatal(1, "FAIL: ALU ADD failed (%0d)", alu_result);
        $display("[PASS] ALU ADD: 15 + 27 = %0d", alu_result);

        // Test ALU_SUB with Zero Flag: 42 - 42 = 0
        alu_a = 32'd42; alu_b = 32'd42; alu_op = ALU_SUB;
        #1;
        assert (alu_result == 32'd0 && zero_flag) 
            else $fatal(1, "FAIL: ALU SUB / Zero flag failed");
        $display("[PASS] ALU SUB & Zero Flag: 42 - 42 = 0 (zero=%b)", zero_flag);

        // Test Signed SLT: -5 < 3 -> 1
        alu_a = -32'sd5; alu_b = 32'sd3; alu_op = ALU_SLT;
        #1;
        assert (alu_result == 32'd1) 
            else $fatal(1, "FAIL: ALU SLT failed");
        $display("[PASS] ALU SLT: -5 < 3 evaluates to %0d", alu_result);

        // Test Arithmetic Shift Right (SRA): -16 >>> 2 = -4
        alu_a = -32'sd16; alu_b = 32'd2; alu_op = ALU_SRA;
        #1;
        assert ($signed(alu_result) == -32'sd4) 
            else $fatal(1, "FAIL: ALU SRA failed");
        $display("[PASS] ALU SRA: -16 >>> 2 = %0d", $signed(alu_result));

        // -----------------------------------------------------------------
        // 2. Test Branch Comparator Conditions
        // -----------------------------------------------------------------
        // Test BEQ (funct3 = 3'b000): 100 == 100 -> taken
        bc_rs1 = 32'd100; bc_rs2 = 32'd100; bc_funct3 = 3'b000;
        #1;
        assert (branch_taken == 1'b1) 
            else $fatal(1, "FAIL: Branch BEQ failed");
        $display("[PASS] Branch BEQ (100 == 100): taken = %b", branch_taken);

        // Test BLT (funct3 = 3'b100): -10 < 5 -> taken
        bc_rs1 = -32'sd10; bc_rs2 = 32'sd5; bc_funct3 = 3'b100;
        #1;
        assert (branch_taken == 1'b1) 
            else $fatal(1, "FAIL: Branch BLT failed");
        $display("[PASS] Branch BLT (-10 < 5): taken = %b", branch_taken);

        // -----------------------------------------------------------------
        // 3. Test Control Decoder Unit
        // -----------------------------------------------------------------
        // Test R-type ADD (opcode = OP_REG, funct3 = 3'b000, funct7[5] = 0)
        ctrl_opcode = OP_REG; ctrl_funct3 = 3'b000; ctrl_funct7_5 = 1'b0;
        #1;
        assert (ctrl_reg_wr == 1'b1 && ctrl_alu_op == ALU_ADD && ctrl_alu_src == 1'b0)
            else $fatal(1, "FAIL: Control R-type ADD decoding failed");
        $display("[PASS] Control R-type ADD decoded correctly.");

        // Test Store SW (opcode = OP_STORE)
        ctrl_opcode = OP_STORE; ctrl_funct3 = 3'b010; ctrl_funct7_5 = 1'b0;
        #1;
        assert (ctrl_mem_wr == 1'b1 && ctrl_imm_src == IMM_S && ctrl_alu_src == 1'b1)
            else $fatal(1, "FAIL: Control Store SW decoding failed");
        $display("[PASS] Control Store SW decoded correctly.");

        // Test Jump JAL (opcode = OP_JAL)
        ctrl_opcode = OP_JAL; ctrl_funct3 = 3'b000; ctrl_funct7_5 = 1'b0;
        #1;
        assert (ctrl_jump == 1'b1 && ctrl_reg_wr == 1'b1 && ctrl_result_src == 2'b10)
            else $fatal(1, "FAIL: Control JAL decoding failed");
        $display("[PASS] Control JAL decoded correctly.");

        $display("=== ALL MILESTONE 2 TESTS PASSED! ===");
        $finish;
    end
endmodule

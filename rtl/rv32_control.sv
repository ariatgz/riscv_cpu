module rv32_control
    import rv32_pkg::*;
(
    input  opcode_e     opcode,
    input  logic [2:0]  funct3,
    input  logic        funct7_5,    // instr[30] for sub/sra distinction
    output imm_src_e    imm_src,
    output logic        alu_src,     // 0 = rs2, 1 = immediate
    output alu_op_e     alu_op,
    output logic        mem_wr,      // 1 = store to data memory
    output logic        reg_wr,      // 1 = write back to register file
    output logic [1:0]  result_src,  // 00 = ALU, 01 = Memory, 10 = PC+4
    output logic        branch,
    output logic        jump
);

    always_comb begin
        // Default safe values (prevents accidental latches)
        imm_src    = IMM_I;
        alu_src    = 1'b0;
        alu_op     = ALU_ADD;
        mem_wr     = 1'b0;
        reg_wr     = 1'b0;
        result_src = 2'b00;
        branch     = 1'b0;
        jump       = 1'b0;

        unique case (opcode)
            OP_IMM: begin
                imm_src    = IMM_I;
                alu_src    = 1'b1;
                reg_wr     = 1'b1;
                result_src = 2'b00;
                // Decode ALU operation for immediate instructions
                unique case (funct3)
                    3'b000: alu_op = ALU_ADD;  // ADDI
                    3'b010: alu_op = ALU_SLT;  // SLTI
                    3'b011: alu_op = ALU_SLTU; // SLTIU
                    3'b100: alu_op = ALU_XOR;  // XORI
                    3'b110: alu_op = ALU_OR;   // ORI
                    3'b111: alu_op = ALU_AND;  // ANDI
                    3'b001: alu_op = ALU_SLL;  // SLLI
                    3'b101: alu_op = funct7_5 ? ALU_SRA : ALU_SRL; // SRAI / SRLI
                    default: alu_op = ALU_ADD;
                endcase
            end

            OP_REG: begin
                alu_src    = 1'b0;
                reg_wr     = 1'b1;
                result_src = 2'b00;
                // Decode ALU operation for register-register instructions
                unique case (funct3)
                    3'b000: alu_op = funct7_5 ? ALU_SUB : ALU_ADD; // SUB / ADD
                    3'b001: alu_op = ALU_SLL;
                    3'b010: alu_op = ALU_SLT;
                    3'b011: alu_op = ALU_SLTU;
                    3'b100: alu_op = ALU_XOR;
                    3'b101: alu_op = funct7_5 ? ALU_SRA : ALU_SRL; // SRA / SRL
                    3'b110: alu_op = ALU_OR;
                    3'b111: alu_op = ALU_AND;
                    default: alu_op = ALU_ADD;
                endcase
            end

            OP_LOAD: begin
                imm_src    = IMM_I;
                alu_src    = 1'b1;
                alu_op     = ALU_ADD;
                reg_wr     = 1'b1;
                result_src = 2'b01; // Data Memory output
            end

            OP_STORE: begin
                imm_src    = IMM_S;
                alu_src    = 1'b1;
                alu_op     = ALU_ADD;
                mem_wr     = 1'b1;
            end

            OP_BRANCH: begin
                imm_src    = IMM_B;
                alu_src    = 1'b0;
                branch     = 1'b1;
            end

            OP_LUI: begin
                imm_src    = IMM_U;
                alu_src    = 1'b1;
                alu_op     = ALU_PASS_B;
                reg_wr     = 1'b1;
                result_src = 2'b00;
            end

            OP_JAL: begin
                imm_src    = IMM_J;
                reg_wr     = 1'b1;
                result_src = 2'b10; // PC + 4
                jump       = 1'b1;
            end

            OP_JALR: begin
                imm_src    = IMM_I;
                reg_wr     = 1'b1;
                result_src = 2'b10; // PC + 4
                jump       = 1'b1;
            end

            default: ;
        endcase
    end

endmodule
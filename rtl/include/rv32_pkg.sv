package rv32_pkg;

    // -------------------------------------------------------------------------
    // 1. Base RV32I 7-bit Opcodes (instr[6:0])
    // -------------------------------------------------------------------------
    typedef enum logic [6:0] {
        OP_LUI    = 7'b0110111, // Load Upper Immediate (U-Type)
        OP_AUIPC  = 7'b0010111, // Add Upper Immediate to PC (U-Type)
        OP_JAL    = 7'b1101111, // Jump and Link (J-Type)
        OP_JALR   = 7'b1100111, // Jump and Link Register (I-Type)
        OP_BRANCH = 7'b1100011, // Conditional Branches (B-Type)
        OP_LOAD   = 7'b0000011, // Memory Loads (I-Type)
        OP_STORE  = 7'b0100011, // Memory Stores (S-Type)
        OP_IMM    = 7'b0010011, // Register-Immediate ALU ops (I-Type)
        OP_REG    = 7'b0110011, // Register-Register ALU ops (R-Type)
        OP_SYSTEM = 7'b1110011  // ECALL / EBREAK / CSRs
    } opcode_e;

    // -------------------------------------------------------------------------
    // 2. Immediate Format Selector (drives rv32_imm_gen)
    // -------------------------------------------------------------------------
    typedef enum logic [2:0] {
        IMM_I = 3'b000, // 12-bit signed (ADDI, LW, JALR)
        IMM_S = 3'b001, // 12-bit signed split (SW, SH, SB)
        IMM_B = 3'b010, // 13-bit signed branch offset (BEQ, BNE, etc.)
        IMM_U = 3'b011, // 20-bit upper immediate (LUI, AUIPC)
        IMM_J = 3'b100  // 21-bit signed jump offset (JAL)
    } imm_src_e;

    // -------------------------------------------------------------------------
    // 3. ALU Operations (we will wire these up in Milestone 2)
    // -------------------------------------------------------------------------
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0000,
        ALU_SUB  = 4'b0001,
        ALU_SLL  = 4'b0010, // Shift Left Logical
        ALU_SLT  = 4'b0011, // Set Less Than (Signed)
        ALU_SLTU = 4'b0100, // Set Less Than (Unsigned)
        ALU_XOR  = 4'b0101,
        ALU_SRL  = 4'b0110, // Shift Right Logical
        ALU_SRA  = 4'b0111, // Shift Right Arithmetic
        ALU_OR   = 4'b1000,
        ALU_AND  = 4'b1001,
        ALU_PASS_B = 4'b1010 // Used for LUI (passes Immediate straight through)
    } alu_op_e;

endpackage
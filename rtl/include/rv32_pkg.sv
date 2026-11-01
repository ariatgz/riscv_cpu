package rv32_pkg;

    // Opcodes
    typedef enum logic [6:0] {
        OP_LUI    = 7'b0110111,
        OP_AUIPC  = 7'b0010111,
        OP_JAL    = 7'b1101111,
        OP_JALR   = 7'b1100111,
        OP_BRANCH = 7'b1100011,
        OP_LOAD   = 7'b0000011,
        OP_STORE  = 7'b0100011,
        OP_IMM    = 7'b0010011,
        OP_REG    = 7'b0110011
    } opcode_e;

    // Immediate Formats
    typedef enum logic [2:0] {
        IMM_I, IMM_S, IMM_B, IMM_U, IMM_J
    } imm_src_e;

    // ALU Operations
    typedef enum logic [3:0] {
        ALU_ADD, ALU_SUB, ALU_SLL, ALU_SLT, ALU_SLTU,
        ALU_XOR, ALU_SRL, ALU_SRA, ALU_OR,  ALU_AND,
        ALU_PASS_B
    } alu_op_e;

    // -------------------------------------------------------------------------
    // Pipeline Register Structs
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] instr;
    } if_id_t;

    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] rs1_data;
        logic [31:0] rs2_data;
        logic [31:0] imm;
        logic [4:0]  rs1_addr;
        logic [4:0]  rs2_addr;
        logic [4:0]  rd_addr;
        logic [2:0]  funct3;       // Added for Branch Comp
        alu_op_e     alu_op;
        logic        alu_src;
        logic        branch;
        logic        jump;
        logic        mem_read;
        logic        mem_write;
        logic [3:0]  dmem_we_mask; 
        logic        reg_write;
        logic        mem_to_reg;
    } id_ex_t;

    typedef struct packed {
        logic [31:0] alu_result;
        logic [31:0] rs2_data;     
        logic [4:0]  rd_addr;
        logic [2:0]  funct3;       // Added for LSU
        logic        mem_read;
        logic        mem_write;
        logic [3:0]  dmem_we_mask;
        logic        reg_write;
        logic        mem_to_reg;
    } ex_mem_t;

    typedef struct packed {
        logic [31:0] alu_result;
        logic [31:0] mem_rdata;
        logic [4:0]  rd_addr;
        logic        reg_write;
        logic        mem_to_reg;
    } mem_wb_t;

endpackage
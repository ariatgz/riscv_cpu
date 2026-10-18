`timescale 1ns / 1ps

module rv32_imm_gen
    import rv32_pkg::*; // Gives us access to imm_src_e
(
    input  logic [31:7] instr_imm_bits, // Bits [6:0] are the opcode, we don't need them here!
    input  imm_src_e    imm_src,
    output logic [31:0] imm_ext
);

    always_comb begin
        unique case (imm_src)
            // I-Type (ADDI, LW, JALR): 12-bit signed immediate in [31:20]
            IMM_I: imm_ext = {{20{instr_imm_bits[31]}}, instr_imm_bits[31:20]};

            // S-Type (SW, SH, SB): 12-bit signed immediate split across [31:25] and [11:7]
            IMM_S: imm_ext = {{20{instr_imm_bits[31]}}, instr_imm_bits[31:25], instr_imm_bits[11:7]};

            // B-Type (BEQ, BNE): 13-bit signed branch offset (Bit 0 is always 0 for 2-byte alignment)
            IMM_B: imm_ext = {{20{instr_imm_bits[31]}}, instr_imm_bits[7], instr_imm_bits[30:25], instr_imm_bits[11:8], 1'b0};

            // U-Type (LUI, AUIPC): 20-bit upper immediate in [31:12], lower 12 bits zeroed
            IMM_U: imm_ext = {instr_imm_bits[31:12], 12'b0};

            // J-Type (JAL): 21-bit signed jump offset (Bit 0 is always 0)
            IMM_J: imm_ext = {{12{instr_imm_bits[31]}}, instr_imm_bits[19:12], instr_imm_bits[20], instr_imm_bits[30:21], 1'b0};

            default: imm_ext = 32'd0;
        endcase
    end

endmodule
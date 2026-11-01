module rv32_control
    import rv32_pkg::*;
(
    input  logic [6:0]  opcode_bits, 
    input  logic [2:0]  funct3,
    input  logic        funct7_5,    
    output imm_src_e    imm_src,
    output logic        alu_src,     
    output alu_op_e     alu_op,
    output logic        mem_wr,      
    output logic        reg_wr,      
    output logic [1:0]  result_src,  
    output logic        branch,
    output logic        jump
);

    always_comb begin
        // Default safe values 
        imm_src    = IMM_I;
        alu_src    = 1'b0;
        alu_op     = ALU_ADD;
        mem_wr     = 1'b0;
        reg_wr     = 1'b0;
        result_src = 2'b00;
        branch     = 1'b0;
        jump       = 1'b0;

        // Cast the raw bits back into the enum INSIDE the module
        unique case (opcode_e'(opcode_bits))
            OP_IMM: begin
                imm_src    = IMM_I;
                alu_src    = 1'b1;
                reg_wr     = 1'b1;
                result_src = 2'b00;
                unique case (funct3)
                    3'b000: alu_op = ALU_ADD;  
                    3'b010: alu_op = ALU_SLT;  
                    3'b011: alu_op = ALU_SLTU; 
                    3'b100: alu_op = ALU_XOR;  
                    3'b110: alu_op = ALU_OR;   
                    3'b111: alu_op = ALU_AND;  
                    3'b001: alu_op = ALU_SLL;  
                    3'b101: alu_op = funct7_5 ? ALU_SRA : ALU_SRL; 
                    default: alu_op = ALU_ADD;
                endcase
            end
            OP_REG: begin
                alu_src    = 1'b0;
                reg_wr     = 1'b1;
                result_src = 2'b00;
                unique case (funct3)
                    3'b000: alu_op = funct7_5 ? ALU_SUB : ALU_ADD; 
                    3'b001: alu_op = ALU_SLL;
                    3'b010: alu_op = ALU_SLT;
                    3'b011: alu_op = ALU_SLTU;
                    3'b100: alu_op = ALU_XOR;
                    3'b101: alu_op = funct7_5 ? ALU_SRA : ALU_SRL; 
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
                result_src = 2'b01; 
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
                result_src = 2'b10; 
                jump       = 1'b1;
            end
            OP_JALR: begin
                imm_src    = IMM_I;
                reg_wr     = 1'b1;
                result_src = 2'b10; 
                jump       = 1'b1;
            end
            default: ;
        endcase
    end
endmodule
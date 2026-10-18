module rv32_alu
    import rv32_pkg::*;
(
    input  logic [31:0]      alu_a,
    input  logic [31:0]      alu_b,
    input  alu_op_e          alu_op,
    output logic [31:0]      alu_result,
    output logic             zero_flag
);

    always_comb begin
        unique case (alu_op)
            ALU_ADD:  alu_result = alu_a + alu_b;
            ALU_SUB:  alu_result = alu_a - alu_b;
            ALU_SLL:  alu_result = alu_a << alu_b[4:0];
            ALU_SLT:  alu_result = ($signed(alu_a) < $signed(alu_b)) ? 32'd1 : 32'd0;
            ALU_SLTU: alu_result = (alu_a < alu_b) ? 32'd1 : 32'd0;
            ALU_XOR:  alu_result = alu_a ^ alu_b;
            ALU_SRL:  alu_result = alu_a >> alu_b[4:0];
            ALU_SRA:  alu_result = $signed(alu_a) >>> alu_b[4:0];
            ALU_OR:   alu_result = alu_a | alu_b;
            ALU_AND:  alu_result = alu_a & alu_b;
            ALU_PASS_B: alu_result = alu_b; // Used for LUI
            default:  alu_result = 32'd0;
        endcase
    end

    assign zero_flag = (alu_result == 32'd0);

endmodule
`timescale 1ns / 1ps
module rv32_branch_comp (
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [2:0]  funct3,
    output logic        branch_taken
);

    logic eq, ne, lt, ltu, ge, geu;

    always_comb begin
        eq  = (rs1_data == rs2_data);
        ne  = ~eq;
        lt  = ($signed(rs1_data) < $signed(rs2_data));
        ltu = (rs1_data < rs2_data);
        ge  = ~lt;
        geu = ~ltu;

        unique case (funct3)
            3'b000:  branch_taken = eq;   // BEQ
            3'b001:  branch_taken = ne;   // BNE
            3'b100:  branch_taken = lt;   // BLT
            3'b101:  branch_taken = ge;   // BGE
            3'b110:  branch_taken = ltu;  // BLTU
            3'b111:  branch_taken = geu;  // BGEU
            default: branch_taken = 1'b0;
        endcase
    end

endmodule

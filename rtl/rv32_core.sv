module rv32_core
    import rv32_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // Instruction Memory Interface
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,

    // Data Memory Interface
    output logic        dmem_wr,      // Tells memory subsystem "a store is happening"
    output logic [3:0]  dmem_we,      // Byte-enable mask from LSU
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input  logic [31:0] dmem_rdata
);

    logic [31:0] pc_q, pc_next, pc_plus_4, pc_target, pc_target_final;
    logic [31:0] instr, imm_ext, alu_result, lsu_rdata, result_wdata;
    logic branch_taken, jump, pc_src;
    logic [31:0] rs1_data, rs2_data;
    logic [31:0] alu_b_mux;

    imm_src_e    imm_src;
    logic        alu_src;
    alu_op_e     alu_op;
    logic        mem_wr, reg_wr;
    logic [1:0]  result_src;

    // =====================================================================
    // DATAPATH MODULE INSTANTIATIONS
    // =====================================================================
    rv32_pc u_pc (
        .clk     (clk),
        .rst_n   (rst_n),
        .pc_next (pc_next),
        .pc_q    (pc_q)
    );

    // Fetch: The IMEM address is just the current PC
    assign imem_addr = pc_q;
    assign instr     = imem_rdata;

    rv32_control u_ctrl (
        .opcode     ( opcode_e'(instr[6:0]) ),
        .funct3     ( instr[14:12] ),
        .funct7_5   ( instr[30] ),
        .imm_src    ( imm_src ),
        .alu_src    ( alu_src ),
        .alu_op     ( alu_op ),
        .mem_wr     ( mem_wr ),
        .reg_wr     ( reg_wr ),
        .result_src ( result_src ),
        .branch     ( branch ),
        .jump       ( jump )
    );

    rv32_regfile u_regfile (
        .clk      (clk),
        .rs1_addr (instr[19:15]),
        .rs1_data (rs1_data),
        .rs2_addr (instr[24:20]),
        .rs2_data (rs2_data),
        .wr_en    (reg_wr),
        .rd_addr  (instr[11:7]),
        .rd_data  (result_wdata) 
    );

    rv32_imm_gen u_imm_gen (
        .instr_imm_bits (instr[31:7]),
        .imm_src        (imm_src),
        .imm_ext        (imm_ext)
    );

    rv32_branch_comp u_branch_comp (
        .rs1_data     (rs1_data),
        .rs2_data     (rs2_data),
        .funct3       (instr[14:12]),
        .branch_taken (branch_taken)
    );

    // ALU Source Mux: Choose between rs2_data or immediate
    assign alu_b_mux = alu_src ? imm_ext : rs2_data;

    rv32_alu u_alu (
        .alu_a      (rs1_data),
        .alu_b      (alu_b_mux),
        .alu_op     (alu_op),
        .alu_result (alu_result),
        .zero_flag  () 
    );

    rv32_lsu u_lsu (
        .funct3      (instr[14:12]),
        .mem_wr      (mem_wr),
        .addr_offset (alu_result[1:0]),
        .rs2_data    (rs2_data),
        .dmem_we     (dmem_we),
        .dmem_wdata  (dmem_wdata),
        .dmem_rdata  (dmem_rdata),
        .lsu_rdata   (lsu_rdata)
    );

    // Wire up Data Memory outputs to top-level ports
    assign dmem_wr   = mem_wr;
    assign dmem_addr = alu_result;



    always_comb begin
        pc_plus_4 = pc_q + 32'd4;
        
        // Target address for B-Type and J-Type is PC + Immediate
        pc_target = pc_q + imm_ext; 
        
        
        pc_target_final = (opcode_e'(instr[6:0]) == OP_JALR) ? alu_result : pc_target;

        pc_src = (branch & branch_taken) | jump;
   
        pc_next = pc_src ? pc_target_final : pc_plus_4;

    end


    always_comb begin
 
        case(result_src)

            2'b00:
                result_wdata = alu_result;
            2'b01:
                result_wdata = lsu_rdata;
            2'b10:
                result_wdata = pc_plus_4;

            default:
                result_wdata = 32'd00;

        endcase
    end

endmodule
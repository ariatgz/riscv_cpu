module rv32_core
    import rv32_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // Instruction Memory Interface
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,

    // Data Memory Interface
    output logic        dmem_wr,      
    output logic [3:0]  dmem_we,      
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input  logic [31:0] dmem_rdata
);

    logic [31:0] pc_q, pc_next;
    
    // Pipeline Registers
    if_id_t   if_id_reg,   if_id_next;
    id_ex_t   id_ex_reg,   id_ex_next;
    ex_mem_t  ex_mem_reg,  ex_mem_next;
    mem_wb_t  mem_wb_reg,  mem_wb_next;

    // Hazard Wires
    logic hazard_stall, hazard_flush_if_id, hazard_flush_id_ex;
    logic ex_branch_taken;
    logic [31:0] ex_branch_target;

// ----------------------------------------------------------------------
// Pipeline State Update (Flip-Flops)
// ----------------------------------------------------------------------
logic branch_flush_delay;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        branch_flush_delay <= 1'b0;
        pc_q       <= 32'h0000_0000;
        if_id_reg  <= '0;
        id_ex_reg  <= '0;
        ex_mem_reg <= '0;
        mem_wb_reg <= '0;
    end else begin
        // Track the BRAM latency delay
        branch_flush_delay <= ex_branch_taken;

        if (ex_branch_taken) begin
            pc_q <= ex_branch_target;
        end else if (!hazard_stall) begin
            pc_q <= pc_next; 
        end

        // CRITICAL FIX: 2-Cycle Flush drops the garbage instruction
        if (hazard_flush_if_id || branch_flush_delay) begin
            if_id_reg <= '0;
        end else if (!hazard_stall) begin
            if_id_reg <= if_id_next;
        end

        if (hazard_flush_id_ex) begin
            id_ex_reg <= '0;
        end else begin
            id_ex_reg <= id_ex_next;
        end

        ex_mem_reg <= ex_mem_next;
        mem_wb_reg <= mem_wb_next;
    end
end

    // ----------------------------------------------------------------------
// Stage 1: Instruction Fetch (IF)
// ----------------------------------------------------------------------
assign imem_addr = pc_q;
assign pc_next   = pc_q + 32'd4; 

// CRITICAL FIX: Subtract 4 to align the PC with the delayed BRAM instruction
assign if_id_next.pc    = pc_q - 32'd4; 
assign if_id_next.instr = imem_rdata;

    // ----------------------------------------------------------------------
    // Stage 2: Instruction Decode (ID)
    // ----------------------------------------------------------------------
    logic [31:0] id_imm, rf_rs1_data, rf_rs2_data, rf_wdata;
    
    logic        id_branch, id_mem_read, id_mem_write, id_alu_src, id_reg_write, id_mem_to_reg, id_jump;
    alu_op_e     id_alu_op;
    logic [3:0]  id_dmem_we_mask;
    logic [1:0]  id_result_src;
    imm_src_e    imm_src;

    rv32_control u_ctrl (
        .opcode_bits ( if_id_reg.instr[6:0] ), 
        .funct3      ( if_id_reg.instr[14:12] ),
        .funct7_5    ( if_id_reg.instr[30] ),
        .imm_src     ( imm_src ),       
        .alu_src     ( id_alu_src ),
        .alu_op      ( id_alu_op ),
        .mem_wr      ( id_mem_write ),
        .reg_wr      ( id_reg_write ),
        .result_src  ( id_result_src ),
        .branch      ( id_branch ),
        .jump        ( id_jump )
    );

    assign id_mem_read   = (id_result_src == 2'b01); 
    assign id_mem_to_reg = (id_result_src == 2'b01);

    always_comb begin
        if (id_mem_write) begin
            case (if_id_reg.instr[14:12]) 
                3'b010: id_dmem_we_mask = 4'b1111; // SW 
                3'b001: id_dmem_we_mask = 4'b0011; // SH 
                3'b000: id_dmem_we_mask = 4'b0001; // SB 
                default: id_dmem_we_mask = 4'b0000;
            endcase
        end else begin
            id_dmem_we_mask = 4'b0000;
        end
    end
    
    rv32_regfile u_regfile (
        .clk      (clk),
        .rs1_addr (if_id_reg.instr[19:15]),
        .rs1_data (rf_rs1_data),
        .rs2_addr (if_id_reg.instr[24:20]),
        .rs2_data (rf_rs2_data),
        .wr_en    (mem_wb_reg.reg_write),
        .rd_addr  (mem_wb_reg.rd_addr),
        .rd_data  (rf_wdata) 
    );

    rv32_imm_gen u_imm_gen (
        .instr_imm_bits (if_id_reg.instr[31:7]),
        .imm_src        (imm_src), 
        .imm_ext        (id_imm)
    );

    assign id_ex_next.pc           = if_id_reg.pc;
    assign id_ex_next.rs1_data     = rf_rs1_data;
    assign id_ex_next.rs2_data     = rf_rs2_data;
    assign id_ex_next.imm          = id_imm;
    assign id_ex_next.rs1_addr     = if_id_reg.instr[19:15];
    assign id_ex_next.rs2_addr     = if_id_reg.instr[24:20];
    assign id_ex_next.rd_addr      = if_id_reg.instr[11:7];
    assign id_ex_next.funct3       = if_id_reg.instr[14:12]; 
    
    assign id_ex_next.alu_op       = id_alu_op;
    assign id_ex_next.alu_src      = id_alu_src;
    assign id_ex_next.branch       = id_branch;
    assign id_ex_next.jump         = id_jump; // Jump wire perfectly aligned
    assign id_ex_next.mem_read     = id_mem_read;
    assign id_ex_next.mem_write    = id_mem_write;
    assign id_ex_next.dmem_we_mask = id_dmem_we_mask;
    assign id_ex_next.reg_write    = id_reg_write;
    assign id_ex_next.mem_to_reg   = id_mem_to_reg;

    // ----------------------------------------------------------------------
    // Stage 3: Execute (EX)
    // ----------------------------------------------------------------------
    logic [1:0]  forward_a, forward_b;
    logic [31:0] fwd_rs1_data, fwd_rs2_data;
    logic [31:0] alu_in_a, alu_in_b;
    logic [31:0] ex_alu_result;
    logic        comp_branch_taken;

    rv32_forwarding u_forward (
        .id_ex_rs1        (id_ex_reg.rs1_addr),
        .id_ex_rs2        (id_ex_reg.rs2_addr),
        .ex_mem_rd        (ex_mem_reg.rd_addr),
        .ex_mem_reg_write (ex_mem_reg.reg_write),
        .mem_wb_rd        (mem_wb_reg.rd_addr),
        .mem_wb_reg_write (mem_wb_reg.reg_write),
        .forward_a        (forward_a),
        .forward_b        (forward_b)
    );

    always_comb begin
        case (forward_a)
            2'b10:   fwd_rs1_data = ex_mem_reg.alu_result; 
            2'b01:   fwd_rs1_data = rf_wdata;              
            default: fwd_rs1_data = id_ex_reg.rs1_data;    
        endcase
    end

    always_comb begin
        case (forward_b)
            2'b10:   fwd_rs2_data = ex_mem_reg.alu_result; 
            2'b01:   fwd_rs2_data = rf_wdata;              
            default: fwd_rs2_data = id_ex_reg.rs2_data;    
        endcase
    end

    assign alu_in_a = fwd_rs1_data;
    assign alu_in_b = id_ex_reg.alu_src ? id_ex_reg.imm : fwd_rs2_data;

    rv32_alu u_alu (
        .alu_a      (alu_in_a),
        .alu_b      (alu_in_b),
        .alu_op     (id_ex_reg.alu_op),
        .alu_result (ex_alu_result),
        .zero_flag  () 
    );

    assign ex_branch_target = id_ex_reg.pc + id_ex_reg.imm;

    rv32_branch_comp u_branch_comp (
        .rs1_data     (fwd_rs1_data),
        .rs2_data     (fwd_rs2_data),
        .funct3       (id_ex_reg.funct3),
        .branch_taken (comp_branch_taken)
    );

    // Branch AND Jump Trigger logic 
    assign ex_branch_taken = (comp_branch_taken & id_ex_reg.branch) | id_ex_reg.jump;

    assign ex_mem_next.alu_result   = ex_alu_result;
    assign ex_mem_next.rs2_data     = fwd_rs2_data; 
    assign ex_mem_next.rd_addr      = id_ex_reg.rd_addr;
    assign ex_mem_next.funct3       = id_ex_reg.funct3; 
    assign ex_mem_next.mem_read     = id_ex_reg.mem_read;
    assign ex_mem_next.mem_write    = id_ex_reg.mem_write;
    assign ex_mem_next.dmem_we_mask = id_ex_reg.dmem_we_mask;
    assign ex_mem_next.reg_write    = id_ex_reg.reg_write;
    assign ex_mem_next.mem_to_reg   = id_ex_reg.mem_to_reg;

    // ----------------------------------------------------------------------
    // Stage 4: Memory Access (MEM)
    // ----------------------------------------------------------------------
    assign dmem_addr = ex_mem_reg.alu_result;
    assign dmem_wr   = ex_mem_reg.mem_write; 
    
    logic [31:0] mem_aligned_rdata;
    
    rv32_lsu u_lsu (
        .funct3      (ex_mem_reg.funct3),
        .mem_wr      (ex_mem_reg.mem_write),
        .addr_offset (ex_mem_reg.alu_result[1:0]),
        .rs2_data    (ex_mem_reg.rs2_data),
        .dmem_we     (dmem_we),         
        .dmem_wdata  (dmem_wdata),      
        .dmem_rdata  (dmem_rdata),      
        .lsu_rdata   (mem_aligned_rdata)
    );

    assign mem_wb_next.alu_result = ex_mem_reg.alu_result;
    assign mem_wb_next.mem_rdata  = mem_aligned_rdata;
    assign mem_wb_next.rd_addr    = ex_mem_reg.rd_addr;
    assign mem_wb_next.reg_write  = ex_mem_reg.reg_write;
    assign mem_wb_next.mem_to_reg = ex_mem_reg.mem_to_reg;

    // ----------------------------------------------------------------------
    // Stage 5: Writeback (WB)
    // ----------------------------------------------------------------------
    assign rf_wdata = mem_wb_reg.mem_to_reg ? mem_wb_reg.mem_rdata 
                                            : mem_wb_reg.alu_result;
                                            
    // ----------------------------------------------------------------------
    // Hazard Detection Unit
    // ----------------------------------------------------------------------
    rv32_hazard u_hazard (
        .if_id_rs1       (if_id_reg.instr[19:15]),
        .if_id_rs2       (if_id_reg.instr[24:20]),
        .id_ex_mem_read  (id_ex_reg.mem_read),
        .id_ex_rd        (id_ex_reg.rd_addr),
        .ex_branch_taken (ex_branch_taken),
        .stall           (hazard_stall),
        .flush_if_id     (hazard_flush_if_id),
        .flush_id_ex     (hazard_flush_id_ex)
    );

endmodule
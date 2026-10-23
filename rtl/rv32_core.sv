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
    logic [31:0] rf_wdata;

    // ----------------------------------------------------------------------
    // Pipeline Registers
    // ----------------------------------------------------------------------
    if_id_t   if_id_reg,   if_id_next;
    id_ex_t   id_ex_reg,   id_ex_next;
    ex_mem_t  ex_mem_reg,  ex_mem_next;
    mem_wb_t  mem_wb_reg,  mem_wb_next;

    imm_src_e    imm_src;
    logic        alu_src;
    alu_op_e     alu_op;
    logic        mem_wr, reg_wr;
    logic [1:0]  result_src;



// ----------------------------------------------------------------------
    // Pipeline State Update (Flip-Flops)
    // ----------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_q       <= 32'h0000_0000;
            if_id_reg  <= '0;
            id_ex_reg  <= '0;
            ex_mem_reg <= '0;
            mem_wb_reg <= '0;
        end else begin
            // 1. PC Update (Freeze on stall, override on branch)
            if (ex_branch_taken) begin
                pc_q <= ex_branch_target;
            end else if (!hazard_stall) begin
                pc_q <= pc_next; // Normal PC + 4
            end

            // 2. IF/ID Register (Freeze on stall, flush on branch)
            if (hazard_flush_if_id) begin
                if_id_reg <= '0;
            end else if (!hazard_stall) begin
                if_id_reg <= if_id_next;
            end

            // 3. ID/EX Register (Flush on load-use stall OR branch)
            if (hazard_flush_id_ex) begin
                id_ex_reg <= '0;
            end else begin
                id_ex_reg <= id_ex_next;
            end

            // 4. EX/MEM and MEM/WB Registers (Always flow forward)
            ex_mem_reg <= ex_mem_next;
            mem_wb_reg <= mem_wb_next;
        end
    end

    // ----------------------------------------------------------------------
    // Stage 1: Instruction Fetch (IF)
    // ----------------------------------------------------------------------
    assign imem_addr = pc_q;
    
    // PC + 4 (For now, we'll add branch logic routing later)
    assign pc_next = pc_q + 32'd4; 

    // Route to Pipeline Register
    assign if_id_next.pc    = pc_q;
    assign if_id_next.instr = imem_rdata;

// ----------------------------------------------------------------------
    // Stage 2: Instruction Decode (ID)
    // ----------------------------------------------------------------------
    logic [31:0] id_imm;
    logic [31:0] rf_rs1_data, rf_rs2_data;
    
    // Register File (Reads in ID, Writes in WB)
    rv32_regfile u_regfile (
        .clk      (clk),
        .rs1_addr (if_id_reg.instr[19:15]),
        .rs1_data (rf_rs1_data),
        .rs2_addr (if_id_reg.instr[24:20]),
        .rs2_data (rf_rs2_data),
        // Writeback connections coming from Stage 5
        .wr_en    (mem_wb_reg.reg_write),
        .rd_addr  (mem_wb_reg.rd_addr),
        .rd_data  (rf_wdata) 
    );

    // Immediate Generator
    rv32_imm_gen u_imm_gen (
        .instr_imm_bits (if_id_reg.instr[31:7]),
        .imm_src        (imm_src), // Make sure u_ctrl outputs this!
        .imm_ext        (id_imm)
    );

  

    // Load ID/EX Pipeline Register
    assign id_ex_next.pc           = if_id_reg.pc;
    assign id_ex_next.rs1_data     = rf_rs1_data;
    assign id_ex_next.rs2_data     = rf_rs2_data;
    assign id_ex_next.imm          = id_imm;
    assign id_ex_next.rs1_addr     = if_id_reg.instr[19:15];
    assign id_ex_next.rs2_addr     = if_id_reg.instr[24:20];
    assign id_ex_next.rd_addr      = if_id_reg.instr[11:7];

    
    // Pass control signals forward to EX, MEM, and WB
    assign id_ex_next.alu_op       = id_alu_op;
    assign id_ex_next.alu_src      = id_alu_src;
    assign id_ex_next.branch       = id_branch;
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
    logic        ex_branch_taken;

    // Forwarding Unit Instantiation
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

    // Forwarding Mux A (rs1)
    always_comb begin
        case (forward_a)
            2'b10:   fwd_rs1_data = ex_mem_reg.alu_result; // From MEM stage
            2'b01:   fwd_rs1_data = rf_wdata;              // From WB stage
            default: fwd_rs1_data = id_ex_reg.rs1_data;    // Normal from ID/EX
        endcase
    end

    // Forwarding Mux B (rs2)
    always_comb begin
        case (forward_b)
            2'b10:   fwd_rs2_data = ex_mem_reg.alu_result; 
            2'b01:   fwd_rs2_data = rf_wdata;              
            default: fwd_rs2_data = id_ex_reg.rs2_data;    
        endcase
    end

    // ALU Inputs (Immediate bypasses rs2 if alu_src is high)
    assign alu_in_a = fwd_rs1_data;
    assign alu_in_b = id_ex_reg.alu_src ? id_ex_reg.imm : fwd_rs2_data;

    // ALU Instantiation
    rv32_alu u_alu (
        .a      (alu_in_a),
        .b      (alu_in_b),
        .op     (id_ex_reg.alu_op),
        .result (ex_alu_result)
    );

    // Branch Target Calculation
    logic [31:0] ex_branch_target;
    assign ex_branch_target = id_ex_reg.pc + id_ex_reg.imm;

    // Branch Condition Evaluation (using ALU or dedicated comparator)
    // For simplicity, assuming a dedicated branch comparator exists:
    rv32_branch_comp u_branch_comp (
        .rs1_data (fwd_rs1_data),
        .rs2_data (fwd_rs2_data),
        .branch_op(id_ex_reg.alu_op), // Or your dedicated branch flags
        .take     (ex_branch_taken)
    );

    // Load EX/MEM Pipeline Register
    assign ex_mem_next.alu_result   = ex_alu_result;
    assign ex_mem_next.rs2_data     = fwd_rs2_data; // Critical: store forwarded data!
    assign ex_mem_next.rd_addr      = id_ex_reg.rd_addr;
    assign ex_mem_next.mem_read     = id_ex_reg.mem_read;
    assign ex_mem_next.mem_write    = id_ex_reg.mem_write;
    assign ex_mem_next.dmem_we_mask = id_ex_reg.dmem_we_mask;
    assign ex_mem_next.reg_write    = id_ex_reg.reg_write;
    assign ex_mem_next.mem_to_reg   = id_ex_reg.mem_to_reg;

    // ----------------------------------------------------------------------
    // Stage 4: Memory Access (MEM)
    // ----------------------------------------------------------------------
    // Route to physical memory interface
    assign dmem_addr  = ex_mem_reg.alu_result;
    assign dmem_wdata = ex_mem_reg.rs2_data;
    assign dmem_we    = ex_mem_reg.mem_write ? ex_mem_reg.dmem_we_mask : 4'b0000;
    
    // LSU Instantiation (Byte alignment for LW, LH, LB)
    logic [31:0] mem_aligned_rdata;
    rv32_lsu u_lsu (
        .addr      (ex_mem_reg.alu_result[1:0]),
        .raw_rdata (dmem_rdata),
        .mask      (ex_mem_reg.dmem_we_mask),
        .mem_read  (ex_mem_reg.mem_read),
        .aligned_data (mem_aligned_rdata)
    );

    // Load MEM/WB Pipeline Register
    assign mem_wb_next.alu_result = ex_mem_reg.alu_result;
    assign mem_wb_next.mem_rdata  = mem_aligned_rdata;
    assign mem_wb_next.rd_addr    = ex_mem_reg.rd_addr;
    assign mem_wb_next.reg_write  = ex_mem_reg.reg_write;
    assign mem_wb_next.mem_to_reg = ex_mem_reg.mem_to_reg;

    // ----------------------------------------------------------------------
    // Stage 5: Writeback (WB)
    // ----------------------------------------------------------------------
    // Ensure this rf_wdata wire connects back to your rv32_regfile instance
    // in the ID stage!
    
    assign rf_wdata = mem_wb_reg.mem_to_reg ? mem_wb_reg.mem_rdata 
                                            : mem_wb_reg.alu_result;
                                            
    // Register File Write Control (routes back to RegFile)
    assign rf_we = mem_wb_reg.reg_write;
    assign rf_rd = mem_wb_reg.rd_addr;

// ----------------------------------------------------------------------
    // Hazard Detection Unit
    // ----------------------------------------------------------------------
    logic hazard_stall, hazard_flush_if_id, hazard_flush_id_ex;

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
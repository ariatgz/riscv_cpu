`timescale 1ns / 1ps

module rv32_forwarding (
    // Current instruction in Execute Stage
    input  logic [4:0] id_ex_rs1,
    input  logic [4:0] id_ex_rs2,
    
    // Older instruction in Memory Stage
    input  logic [4:0] ex_mem_rd,
    input  logic       ex_mem_reg_write,
    
    // Oldest instruction in Writeback Stage
    input  logic [4:0] mem_wb_rd,
    input  logic       mem_wb_reg_write,
    
    // Output to the Execute Stage Multiplexers
    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

    // ----------------------------------------------------------------------
    // Forward A (rs1) Logic
    // ----------------------------------------------------------------------
    always_comb begin
        // 1. EX Hazard: The prior instruction wrote to rs1
        // (Must ensure rd != 0, because writing to x0 is ignored in RISC-V)
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b10;
        end
        // 2. MEM Hazard: The instruction two cycles ago wrote to rs1
        else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1)) begin
            forward_a = 2'b01;
        end
        // 3. No Hazard: Read normally from the ID/EX pipeline register
        else begin
            forward_a = 2'b00;
        end
    end

    // ----------------------------------------------------------------------
    // Forward B (rs2) Logic
    // ----------------------------------------------------------------------
    always_comb begin
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end
        else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs2)) begin
            forward_b = 2'b01;
        end
        else begin
            forward_b = 2'b00;
        end
    end

endmodule

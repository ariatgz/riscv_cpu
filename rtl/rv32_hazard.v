`timescale 1ns / 1ps

module rv32_hazard (
    // Load-Use Detection Signals
    input  logic [4:0] if_id_rs1,
    input  logic [4:0] if_id_rs2,
    input  logic       id_ex_mem_read,
    input  logic [4:0] id_ex_rd,
    
    // Branch Flush Signal
    input  logic       ex_branch_taken,
    
    // Control Outputs
    output logic       stall,        // Freezes PC and IF/ID
    output logic       flush_if_id,  // Clears IF/ID on branch
    output logic       flush_id_ex   // Clears ID/EX on stall or branch
);

    logic load_use_hazard;

    // Detect if the instruction in EX is a Load AND its destination matches our sources
    always_comb begin
        if (id_ex_mem_read && (id_ex_rd != 5'd0) && 
           ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))) begin
            load_use_hazard = 1'b1;
        end else begin
            load_use_hazard = 1'b0;
        end
    end

    // Assign control outputs
    assign stall       = load_use_hazard;
    assign flush_id_ex = load_use_hazard || ex_branch_taken;
    assign flush_if_id = ex_branch_taken;

endmodule

`timescale 1ns / 1ps


module rv32_regfile (
    input  logic        clk,
    // Read Port 1 (Asynchronous / Combinational)
    input  logic [4:0]  rs1_addr,
    output logic [31:0] rs1_data,
    // Read Port 2 (Asynchronous / Combinational)
    input  logic [4:0]  rs2_addr,
    output logic [31:0] rs2_data,
    // Write Port (Synchronous on posedge clk)
    input  logic        wr_en,
    input  logic [4:0]  rd_addr,
    input  logic [31:0] rd_data
);

    // Hint to Vivado to infer Distributed LUTRAM (RAM32M) instead of 1024 Flip-Flops
    (* ram_style = "distributed" *) logic [31:0] regs [0:31];

    // Optional: Initialize to 0 for clean simulation waveforms
    // (Vivado ignores this for x0 because of our combinational read mux below)
    initial begin
        for (int i = 0; i < 32; i++) begin
            regs[i] = 32'd0;
        end
    end

    // Synchronous Write: Ignore writes to x0 (5'd0)
    always_ff @(posedge clk) begin
        if (wr_en && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= rd_data;
        end
    end

    // Asynchronous Reads: Hardwire x0 (5'd0) to return 32'd0
    always_comb begin
        rs1_data = (rs1_addr == 5'd0) ? 32'd0 : regs[rs1_addr];
        rs2_data = (rs2_addr == 5'd0) ? 32'd0 : regs[rs2_addr];
    end

endmodule

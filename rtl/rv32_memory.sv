`timescale 1ns / 1ps
module rv32_memory #(
    parameter MEM_SIZE_WORDS = 4096, // 16 KB
    parameter INIT_FILE = "program.mem"
)(
    input  logic        clk,
    // Instruction Read Port
    input  logic [31:0] imem_addr,
    output logic [31:0] imem_rdata,
    // Data Read/Write Port
    input  logic        dmem_wr,
    input  logic [3:0]  dmem_we,
    input  logic [31:0] dmem_addr,
    input  logic [31:0] dmem_wdata,
    output logic [31:0] dmem_rdata
);

    // The physical memory arrays
    logic [31:0] instr_ram [0:MEM_SIZE_WORDS-1];
    logic [31:0] data_ram  [0:MEM_SIZE_WORDS-1];

    // Load the compiled software into memory when the FPGA boots!
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, instr_ram);
            // Optional: You can load a separate data file here if needed
            // $readmemh("data.mem", data_ram); 
        end
    end

    // ---------------------------------------------------------
    // IMEM: Asynchronous Read (Required for Single-Cycle)
    // ---------------------------------------------------------
    // Divide byte address by 4 to get the word index [31:2]
    assign imem_rdata = instr_ram[imem_addr[31:2]];

    // ---------------------------------------------------------
    // DMEM: Synchronous Write, Asynchronous Read
    // ---------------------------------------------------------
    assign dmem_rdata = data_ram[dmem_addr[31:2]];

    always_ff @(posedge clk) begin
        if (dmem_wr) begin
            // Byte-enable masking
            if (dmem_we[0]) data_ram[dmem_addr[31:2]][ 7: 0] <= dmem_wdata[ 7: 0];
            if (dmem_we[1]) data_ram[dmem_addr[31:2]][15: 8] <= dmem_wdata[15: 8];
            if (dmem_we[2]) data_ram[dmem_addr[31:2]][23:16] <= dmem_wdata[23:16];
            if (dmem_we[3]) data_ram[dmem_addr[31:2]][31:24] <= dmem_wdata[31:24];
        end
    end

endmodule

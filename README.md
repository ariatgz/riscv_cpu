# RV32I SystemVerilog Processor

## Overview
This repository contains a from-scratch implementation of a 32-bit RISC-V processor based on the RV32I Base Integer Instruction Set Architecture. It is written entirely in SystemVerilog and currently features a working single-cycle datapath capable of executing compiled C/Assembly code via a simulated Harvard memory architecture.

The project is actively developed and currently verified using AMD/Xilinx Vivado behavioral simulation. 

## Architecture
The current implementation is a single-cycle core with the following characteristics:
* **ISA Support:** RV32I (Base Integer Instruction Set)
* **Datapath:** Single-cycle, non-pipelined (Pipeline upgrade in progress)
* **Memory Architecture:** Harvard (Separate Instruction and Data Memory)
* **Register File:** 32x32-bit, utilizing distributed LUTRAM inference with asynchronous reads
* **Control Logic:** Hardwired centralized control unit and local ALU decoding
* **Load/Store Unit (LSU):** Handles byte-lane alignment and sign/zero-extension for byte, halfword, and word memory accesses

## Repository Structure
```text
├── rtl/                        # Synthesizable SystemVerilog design files
│   ├── rv32_pkg.sv             # Global architecture parameters and opcodes
│   ├── rv32_pc.sv              # Program Counter
│   ├── rv32_alu.sv             # Arithmetic Logic Unit
│   ├── rv32_branch_comp.sv     # Branch Evaluation Unit
│   ├── rv32_imm_gen.sv         # Immediate Generator
│   ├── rv32_regfile.sv         # 32-word Register File
│   ├── rv32_control.sv         # Main Control Decoder
│   ├── rv32_lsu.sv             # Load/Store Byte-Alignment Unit
│   ├── rv32_memory.sv          # BRAM Inference (IMEM & DMEM)
│   └── rv32_core.sv            # Top-level CPU integration
├── tb/                         # Simulation testbenches
│   ├── tb_milestone2.sv        # ALU/Control unit tests
│   ├── tb_milestone3_lsu.sv    # Load/Store unit tests
│   └── tb_milestone3_system.sv # Top-level system execution testbench
└── software/                   # Assembly programs and compiled hex files
    ├── fibonacci.s             # Example sequence generator
    └── program.mem             # Byte-swapped hex machine code for Vivado
```

## Prerequisites
* **Simulation & Synthesis:** AMD Vivado Design Suite (tested on 2023.x / 2024.x)
* **Software Compilation:** RISC-V GNU Compiler Toolchain (`riscv64-unknown-elf-gcc`)

## Simulation and Testing
1. Clone the repository and create a new Vivado project.
2. Add all `.sv` files in `rtl/` as Design Sources.
3. Add all `.sv` files in `tb/` as Simulation Sources.
4. Add `software/program.mem` as a Simulation Source to ensure it is copied into the `xsim` working directory.
5. Set `tb_milestone3_system` as the top simulation module.
6. Run Behavioral Simulation. Ensure the Display Limit is increased if inspecting the full `data_ram` array.

## Compiling Custom Software
To write and run your own assembly or C code on this processor, compile the code using the RISC-V GNU toolchain and convert the resulting ELF binary into a raw hexadecimal format.

```bash
# Assemble the code
riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 program.s -o program.elf

# Extract raw hex (Note: requires byte-swapping for Vivado $readmemh compatibility)
riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 program.elf program.mem
```

*Note: Vivado's `$readmemh` expects Big-Endian byte ordering for text files, while the RISC-V architecture is Little-Endian. Ensure your compilation step or Verilog memory wrapper swaps the byte ordering of the generated `.mem` file prior to execution.*

## Roadmap
This project is part of an ongoing progression toward a complete System-on-Chip (SoC).

- [x] **Phase 1:** Single-Cycle RV32I Datapath
- [x] **Phase 2:** Behavioral Simulation & Toolchain Integration
- [x] **Phase 3:** 5-Stage Pipelining (Fetch, Decode, Execute, Memory, Writeback)
- [x] **Phase 4:** Hazard Detection and Data Forwarding Units
- [ ] **Phase 5:** Memory-Mapped I/O and AXI4-Lite Bus Integration
- [ ] **Phase 6:** UART Peripheral implementation
- [ ] **Phase 7:** Physical deployment on an AMD Artix-7 / Zynq-7000 FPGA

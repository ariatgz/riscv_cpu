.section .text
.globl _start

_start:
    # 1. Forwarding Test
    addi x1, x0, 10      
    addi x2, x1, 5       # EX Hazard: Needs x1 instantly. x2 should be 15.

    # 2. Load-Use Stall Test
    sw   x2, 0(x0)       # Store 15 to memory
    lw   x3, 0(x0)       # Load 15 into x3
    add  x4, x3, x3      # Load-Use Hazard: CPU MUST stall for 1 cycle here. x4 = 30.

    # 3. Branch Flush Test
    beq  x4, x4, target  # 30 == 30, branch taken!
    addi x5, x0, 99      # FLUSH THIS (In Decode)
    addi x5, x0, 99      # FLUSH THIS (In Fetch)

target:
    addi x6, x0, 100     # Valid execution resumes. x6 = 100.
    
end:
    jal  x0, end         # Infinite trap
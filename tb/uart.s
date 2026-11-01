.section .text
.globl _start

_start:
    # Set x1 to the UART MMIO physical address (0x8000_0000)
    lui x1, 0x80000

    # Set x2 to ASCII 'H' (0x48)
    addi x2, x0, 0x48

loop:
    # Write 'H' into the UART
    sw x2, 0(x1)

    # Delay loop to prevent flooding the PC terminal (adjust as needed)
    lui x3, 0x10      
delay:
    addi x3, x3, -1
    bne x3, x0, delay

    jal x0, loop
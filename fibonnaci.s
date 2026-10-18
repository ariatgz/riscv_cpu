.text
.global _start

_start:
    li x10, 0x1000      # x10 = Base memory address to store the sequence
    li x1, 0            # x1 = Fib[n-2] (Starts at 0)
    li x2, 1            # x2 = Fib[n-1] (Starts at 1)
    li x3, 10           # x3 = Loop counter (Calculate 10 numbers)
    
    # Store the first two numbers
    sw x1, 0(x10)       # Mem[0x1000] = 0
    sw x2, 4(x10)       # Mem[0x1004] = 1
    addi x10, x10, 8    # Advance memory pointer by 8 bytes
    
fib_loop:
    beq x3, zero, done  # If counter == 0, exit loop
    add x4, x1, x2      # x4 = x1 + x2 (The next Fibonacci number)
    sw x4, 0(x10)       # Store it to memory
    
    # Shift registers for next iteration
    mv x1, x2           # x1 = x2
    mv x2, x4           # x2 = x4
    
    # Update loop tracking
    addi x10, x10, 4    # Advance memory pointer
    addi x3, x3, -1     # Decrement counter
    j fib_loop          # Jump back to start of loop

done:
    j done              # Infinite loop to gracefully halt
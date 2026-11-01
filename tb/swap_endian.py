import sys

if len(sys.argv) != 3:
    print("Usage: python swap_endian.py <input.mem> <output.mem>")
    sys.exit(1)

with open(sys.argv[1], 'r') as f_in, open(sys.argv[2], 'w') as f_out:
    for line in f_in:
        line = line.strip()
        # Only swap standard 32-bit (8 character) hex strings
        if len(line) == 8:
            # Slices the string to swap: Byte 3, Byte 2, Byte 1, Byte 0
            swapped = line[6:8] + line[4:6] + line[2:4] + line[0:2]
            f_out.write(swapped + '\n')
        else:
            f_out.write(line + '\n')
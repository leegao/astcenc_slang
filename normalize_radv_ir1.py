import re, sys
a = open(sys.argv[1], "r").read()

# RADV ISA ir dump
#             16     %8098 = fround_even %8097
# normalize all of the vregs (%1234) to (%1200) (mod 100)

def normalize_vregs(s):
    lines = []
    for line in s.split("\n"):
        lines.append(re.sub(r'%([0-9]+)', r'%__', line))
    return "\n".join(lines)

print(normalize_vregs(a))
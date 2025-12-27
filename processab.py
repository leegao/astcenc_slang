import re, sys
a = open(sys.argv[1], "r").read()

# RADV ISA ir dump
# buffer_store_short v19, v1, s[0:3], 0 offen offset:32       ; e0681020 80001301
# normalize all of the vregs v\d+, s\d+, v[.+], s[.+]
# remove all comments: \s+;.+

def normalize_vregs(s):
    lines = []
    for line in s.split("\n"):
        line = re.sub(r'v(\d+)', r'v_', line)
        line = re.sub(r's(\d+)', r's_', line)
        line = re.sub(r'v\[(.+?)\]', r'v[___]', line)
        line = re.sub(r's\[(.+?)\]', r's[___]', line)
        line = re.sub(r'\s+;.+', '', line)
        lines.append(line)
    return "\n".join(lines)

print(normalize_vregs(a))
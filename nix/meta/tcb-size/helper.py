import os
import sys
import json

obj = json.load(sys.stdin)

def size_of(path):
    return os.stat(path).st_size

size = 0
for path in obj['whole']:
    size += size_of(path)
for path in obj['untrusted']:
    size -= size_of(path)

k = size // 1024

print("{}K".format(k))

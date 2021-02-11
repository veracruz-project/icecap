import json
import re
import sys

files = {}
for line in sys.stdin:
    m = re.compile(r'(?P<sha256>[0-9a-f]{64})  ./(?P<path>.+)\n').fullmatch(line)
    assert m is not None
    files[m['path']] = m['sha256']

meta = {
    'files': files,
    'package': sys.argv[1] if len(sys.argv) >= 2 else None,
    }

with open('.cargo-checksum.json', 'w') as f:
    json.dump(meta, f)

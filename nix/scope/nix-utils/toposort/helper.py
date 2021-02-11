import sys
import json
from toposort import toposort

raw = json.load(sys.stdin)
unsorted = { k: set(v) for k, v in raw.items() }
sorted = [ list(v) for v in toposort(unsorted) ]

json.dump(sorted, sys.stdout)

import sys
import toml

name = sys.argv[1]

paths = set()
for line in sys.stdin:
    path = line.rstrip()
    manifest = toml.load(path)
    if "package" in manifest:
        if name == manifest["package"]["name"]:
            paths.add(path)

assert(len(paths) == 1)
for path in paths:
    print(path)

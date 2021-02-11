import sys
import json
import toml

toml.dump(json.load(sys.stdin), sys.stdout)

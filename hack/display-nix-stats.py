#!/usr/bin/env python3

# Use with the output of anything like the following:
# NIX_SHOW_STATS=1 NIX_SHOW_STATS_PATH=stats.json NIX_COUNT_CALLS=1 nix-instantiate --dry-run -A <attr>

import sys
import json
from argparse import ArgumentParser, FileType

def main():
    parser = ArgumentParser()
    parser.add_argument('view')
    parser.add_argument('stats_file', type=FileType('r'), nargs='?', default=sys.stdin)
    args = parser.parse_args()

    obj = json.load(args.stats_file)

    if 'summary'.startswith(args.view):
        del obj['attributes']
        del obj['functions']
        print(json.dumps(obj, indent=4, sort_keys=True))

    elif 'functions'.startswith(args.view):
        def f(entry):
            name = '' if entry['name'] is None else entry['name']
            file_ = entry['file'] if entry['file'].startswith('/') else '(inline)'
            return '{:8} {:25} {}:{},{}'.format(
                entry['count'], name, file_, entry['line'], entry['column'])
        for entry in sorted(obj['functions'], key=lambda entry: entry['count']):
            print(f(entry))

    elif 'attributes'.startswith(args.view):
        def f(entry):
            return '{:8} {}:{},{}'.format(
                entry['count'], entry['file'], entry['line'], entry['column'])
        for entry in sorted((entry for entry in obj['attributes'] if len(entry) > 1), key=lambda entry: entry['count']):
            print(f(entry))

    else:
        raise Exception

if __name__ == '__main__':
    main()

#!/usr/bin/env python3

import sys

def check(content):
    if len(content) > 0 and content[-1] != ord('\n'):
        return False
    if len(content) > 1 and content[-2] == ord('\n'):
        return False
    return True

def main():
    path = sys.argv[1]
    with open(path, 'rb') as f:
        content = f.read()
    if not check(content):
        print("!", path)
        sys.exit(1)

if __name__ == '__main__':
    main()

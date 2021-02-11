import re
import sys
import os.path
from argparse import ArgumentParser, FileType

r_project = re.compile('project (?P<project>.*)\n')
r_header = re.compile(r'(?P<prefix>(--- a|\+\+\+ b)/)(?P<path>.*)\n')

def stream(infile, outfile):
    project = None
    for line in infile:
        m = r_project.fullmatch(line)
        if m is not None:
            project = m['project']
        m = r_header.fullmatch(line)
        if m is not None:
            assert project is not None
            line = m['prefix'] + project + m['path'] + '\n'
        outfile.write(line)

def main():
    parser = ArgumentParser()
    parser.add_argument('infile', nargs='?', type=FileType('r'), default=sys.stdin)
    parser.add_argument('outfile', nargs='?', type=FileType('w'), default=sys.stdout)
    args = parser.parse_args()
    stream(args.infile, args.outfile)

if __name__ == '__main__':
    main()

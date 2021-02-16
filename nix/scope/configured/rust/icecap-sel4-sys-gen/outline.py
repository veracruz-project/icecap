import re
from argparse import ArgumentParser, FileType

def main():
    parser = ArgumentParser()
    parser.add_argument('infile', type=FileType('r'))
    parser.add_argument('--prefix')
    parser.add_argument('--out-c', type=FileType('a'))
    parser.add_argument('--out-h', type=FileType('a'))
    args = parser.parse_args()
    raw = args.infile.read()
    outline(args, raw)

def outline(ctx, raw):
    sig_re = re.compile(r'static\s+inline\s+(?P<sig>[^;{]+)')
    for m in sig_re.finditer(raw):
        sig = normalize_whitespace(remove_attributes(m['sig']))
        outline_sig(ctx, sig)

attributes = [
    r'__unused__',
    r'__pure__',
    r'__const__',
    r'unused',
    r'warn_unused_result',
    r'deprecated\("[^"]*"\)',
    r'always_inline', # TODO sketchy
    ]

attribute_alt = '|'.join(attributes)
attribute_re = re.compile(r'__attribute__\(\(({})\)\)'.format(attribute_alt))
def remove_attributes(x):
    return attribute_re.sub('', x)

whitespace_re = re.compile('\s+')
def normalize_whitespace(x):
    return whitespace_re.sub(' ', x)

outer_re = re.compile(r' *(?P<type>([a-zA-Z_][a-zA-Z0-9_]* +)*[a-zA-Z_][a-zA-Z0-9_]*( +\* *| *\* +| +))(?P<name>[a-zA-Z_][a-zA-Z0-9_]*)\((?P<args>[^)]*)\) *')
sep_re = re.compile(r' *, *')
arg_re = re.compile(r'.*?(?P<arg>[a-zA-Z_][a-zA-Z0-9_]*)(\[\])? *$')
# TODO tidy upstream
# arg_re = re.compile(r'.*?(?P<arg>[a-zA-Z_][a-zA-Z0-9_]*)(\[\])?$')
def outline_sig(ctx, sig):
    outer = outer_re.fullmatch(sig)
    assert outer is not None
    ty = outer['type'].strip(' ')
    name = outer['name']
    raw_args = outer['args']
    args = []
    varargs = False
    for raw_arg in sep_re.split(raw_args):
        assert not varargs
        if raw_arg == '...':
            varargs = True
            continue
        m = arg_re.fullmatch(raw_arg)
        if m is None:
            print("bad")
            print(repr(raw_arg))
            print(sig)
        assert m is not None
        args.append(m['arg'])
    if 'void' in args:
        assert len(args) == 1
        args = []
    return emit(ctx, ty, name, raw_args, args, varargs)

seen = {}

def emit(ctx, ty, name, raw_args, args, varargs):
    if varargs:
        # unimplemented
        return
    if name in seen:
        ty_, args_, varargs_ = seen[name]
        assert ty == ty_
        assert varargs == varargs_
        assert len(args) == len(args_)
        return
    seen[name] = ty, args, varargs
    ret = '' if ty == 'void' else 'return '
    arg_idents = ', '.join(args)
    print(f'{ty} {ctx.prefix}{name}({raw_args});', file=ctx.out_h)
    print(f'{ty} {ctx.prefix}{name}({raw_args})', file=ctx.out_c)
    print('{', file=ctx.out_c)
    print(f'    {ret}{name}({arg_idents});', file=ctx.out_c)
    print('}', file=ctx.out_c)
    print(file=ctx.out_c)

if __name__ == '__main__':
    main()

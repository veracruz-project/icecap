LEVEL_SIZE_BITS = 9

PAGE_SIZE_BITS = 12
PAGE_SIZE = 1 << PAGE_SIZE_BITS

BLOCK_SIZE_BITS = PAGE_SIZE_BITS + LEVEL_SIZE_BITS
BLOCK_SIZE = 1 << BLOCK_SIZE_BITS

def block_at(a, b, c):
    return \
        a * (1 << (LEVEL_SIZE_BITS * 2)) + \
        b * (1 << (LEVEL_SIZE_BITS * 1)) + \
        c * (1 << (LEVEL_SIZE_BITS * 0))

def page_at(a, b, c, d):
    return block_at(a, b, c) << LEVEL_SIZE_BITS + d

def vaddr_at_block(a, b, c):
    return block_at(a, b, c) << BLOCK_SIZE_BITS

def vaddr_at_page(a, b, c, d):
    return block_at(a, b, c, d) << PAGE_SIZE_BITS

def align_up(x, m):
    return ((x - 1) | (m - 1)) + 1

def mk_fill(frame_offset, length, fname, file_offset):
    return ['{} {} CDL_FrameFill_FileData "{}" {}'.format(frame_offset, length, fname, file_offset)]

def as_(g):
    def wrapper(f):
        def wrapped(*args, **kwargs):
            return g(*f(*args, **kwargs))
        return wrapped
    return wrapper

def as_list(f):
    def wrapped(*args, **kwargs):
        return list(f(*args, **kwargs))
    return wrapped

def groups_of(n, it):
    l = list(it)
    for i in range(0, len(l), n):
        yield l[i:i+n]

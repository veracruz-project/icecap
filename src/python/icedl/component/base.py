from capdl import ObjectType, CSpaceAllocator, AddressSpaceAllocator, Cap

from icedl.utils import PAGE_SIZE, BLOCK_SIZE, align_up, mk_fill

class BaseComponent:

    def __init__(self, composition, name):
        self.composition = composition
        self.key = name
        self.name = name

        cnode = self.alloc(ObjectType.seL4_CapTableObject, 'cnode')
        self.render_state().cspaces[self.key] = CSpaceAllocator(cnode)
        pd = self.alloc(self.composition.arch.vspace().object, 'pgd')
        addr_space = AddressSpaceAllocator('{}_addr_space'.format(self.key), pd)
        self.render_state().pds[self.key] = pd
        self.render_state().addr_spaces[self.key] = addr_space

        self.cnode_cap = Cap(self.cspace().cnode)
        self.cspace().cnode.update_guard_size_caps.append(self.cnode_cap)

    def render_state(self):
        return self.composition.render_state

    def obj_space(self):
        return self.render_state().obj_space

    def pd(self):
        return self.render_state().pds[self.key]

    def addr_space(self):
        return self.render_state().addr_spaces[self.key]

    def cspace(self):
        return self.render_state().cspaces[self.key]

    def alloc(self, type, name, *args, **kwargs):
        name = '{}_{}'.format(self.name, name) # TODO is this sound?
        return self.obj_space().alloc(type, name, *args, label=self.key, **kwargs)

    def finalize(self):
        self.cspace().cnode.finalise_size(arch=self.composition.arch)

    def fmt(self, s, *args):
        return s.format(self.name, *args)

    def config(self):
        return self.composition.config['components'][self.name]

    def map_with_size(self, size, vaddr, paddr=None, fill=[], label=None, read=False, write=False, execute=False, cached=True):
        assert vaddr % size == 0
        name = ''
        if label is not None:
            name += label + '_'
        name += '0x{:x}'.format(vaddr)
        frame = self.alloc(ObjectType.seL4_FrameObject, name, size=size, fill=fill, paddr=paddr)
        cap = Cap(frame, read=read, write=write, grant=execute, cached=cached)
        self.addr_space().add_hack_page(vaddr, size, cap)

    def map_page(self, *args, **kwargs):
        self.map_with_size(PAGE_SIZE, *args, **kwargs)

    def map_block(self, *args, **kwargs):
        self.map_with_size(BLOCK_SIZE, *args, **kwargs)

    def map_range(self, vaddr_start, vaddr_end, label=None):
        assert vaddr_start % PAGE_SIZE == 0
        assert vaddr_end % PAGE_SIZE == 0
        vaddr = vaddr_start
        while vaddr < vaddr_end:
            if vaddr % BLOCK_SIZE == 0 and vaddr + BLOCK_SIZE <= vaddr_end:
                size = BLOCK_SIZE
            else:
                size = PAGE_SIZE
            self.map_with_size(size, vaddr, label=label, read=True, write=True)
            vaddr += size

    def map_file(self, vaddr_start, fname: str, path, label=None):
        self.composition.register_file(fname, path)
        file_size = path.stat().st_size
        vaddr_end = vaddr_start + align_up(file_size, PAGE_SIZE)
        assert vaddr_start % PAGE_SIZE == 0
        assert vaddr_end % PAGE_SIZE == 0
        vaddr = vaddr_start
        while vaddr < vaddr_end:
            if vaddr % BLOCK_SIZE == 0 and vaddr + BLOCK_SIZE <= vaddr_end:
                size = BLOCK_SIZE
            else:
                size = PAGE_SIZE
            file_offset = vaddr - vaddr_start
            fill = mk_fill(0, min(size, file_size - file_offset), fname, file_offset)
            self.map_with_size(size, vaddr, label=label, read=True, write=True, fill=fill)
            vaddr += size
        return vaddr_end

    # extern

    def extern_cap(self, ty, name, **cap_kwargs):
        return self.cspace().alloc(self.composition.extern(ty, name), **cap_kwargs)

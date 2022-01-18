from capdl import ObjectType, Cap
from icecap_framework import ElfComponent
from icecap_framework.utils import BLOCK_SIZE, PAGE_SIZE

class SimpleRealizer(ElfComponent):

    def __init__(self, *args, ut_size_bits_spec=None, root_cnode_size_bits=14, allocator_cnode_size_bits=18, **kwargs):
        super().__init__(*args, update_guard_size=False, **kwargs)

        assert ut_size_bits_spec is not None

        # HACK
        self.cspace().cnode.size_bits = root_cnode_size_bits

        # FORBIDDEN HACK
        hack_guard_size = self.composition.arch.word_size_bits() - 2*root_cnode_size_bits
        self.cspace().cnode.slots[0] = Cap(self.cspace().cnode, guard=0, guard_size=hack_guard_size)

        allocator_cnode = self.alloc(ObjectType.seL4_CapTableObject, name='allocator_cnode', size_bits=allocator_cnode_size_bits)
        allocator_cnode_shift = root_cnode_size_bits

        for i, ut_size_bits in enumerate(ut_size_bits_spec):
            ut_slot = self.cspace().alloc(self.alloc(ObjectType.seL4_UntypedObject, name='allocator_untyped_{}'.format(i), size_bits=ut_size_bits))
            ut = {
                'slot': ut_slot,
                'size_bits': ut_size_bits,
                'paddr': i,
                'device': False,
            }

        self.align(BLOCK_SIZE)
        large_frame_addr = self.cur_vaddr
        self.skip(BLOCK_SIZE)
        small_frame_addr = self.cur_vaddr
        self.skip(PAGE_SIZE)
        small_frame_obj = self.alloc(ObjectType.seL4_FrameObject, name='dummy_small_frame', size=PAGE_SIZE)
        large_frame_obj = self.alloc(ObjectType.seL4_FrameObject, name='dummy_large_frame', size=BLOCK_SIZE)
        small_frame = self.cspace().alloc(small_frame_obj)
        self.addr_space().add_hack_page(small_frame_addr, PAGE_SIZE, Cap(small_frame_obj, read=True, write=True))
        large_frame = self.cspace().alloc(large_frame_obj)
        self.addr_space().add_hack_page(large_frame_addr, BLOCK_SIZE, Cap(large_frame_obj, read=True, write=True))

        self.endpoints = [
            self.alloc(ObjectType.seL4_EndpointObject, 'ep_{}'.format(i))
            for i in range(self.composition.num_nodes())
            ]
        self.bound_notifications = [
            self.alloc(ObjectType.seL4_NotificationObject, 'nfn_{}'.format(i))
            for i in range(self.composition.num_nodes())
            ]

        self.realizer_config = {
            'initialization_resources': {
                'pgd': self.cspace().alloc(self.pd(), write=True),
                'asid_pool': self.cspace().alloc(self.alloc(ObjectType.seL4_ASID_Pool, 'asid_pool_{}'.format(self.name))),
                'tcb_authority': self.cspace().alloc(self.primary_thread.tcb),
                'small_page_addr': small_frame_addr,
                'large_page_addr': large_frame_addr,
                },
            'small_page': small_frame,
            'large_page': large_frame,
            'allocator_cregion': {
                'root': {
                    'root': self.cspace().alloc(self.cspace().cnode, write=True, update_guard_size=False),
                    'cptr': self.cspace().alloc(allocator_cnode, write=True, update_guard_size=False),
                    'depth': root_cnode_size_bits,
                },
                'guard': 0,
                'guard_size': 0,
                'slots_size_bits': allocator_cnode_size_bits,
            },
            'untyped': [ut],
            'externs': {},
            }

    def add_extern(self, ident, ty, cptr):
        self.realizer_config['externs'][ident] = {
            'ty': ty,
            'cptr': cptr,
            }

    def add_extern_ring_buffer(self, tag, objs):
        def add(obj, ty, *segs, **cap_kwargs):
            ident = '{}_{}'.format(tag, '_'.join(map(str, segs)))
            self.add_extern(ident, ty, self.cspace().alloc(obj, **cap_kwargs))

        def add_frame(obj, *segs, **cap_kwargs):
            frame, size_bits = obj
            if size_bits == 12:
                ty = 'SmallPage'
            if size_bits == 21:
                ty = 'LargePage'
            add(frame, ty, *segs, **cap_kwargs)

        for i, obj in enumerate(objs.read.ctrl):
            add_frame(obj, 'read', 'ctrl', i, read=True, write=True)
        for i, obj in enumerate(objs.write.ctrl):
            add_frame(obj, 'write', 'ctrl', i, read=True, write=True)
        for i, obj in enumerate(objs.read.data):
            add_frame(obj, 'read', 'data', i, read=True)
        for i, obj in enumerate(objs.write.data):
            add_frame(obj, 'write', 'data', i, read=True, write=True)

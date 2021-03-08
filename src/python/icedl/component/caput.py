from pathlib import Path
from capdl import ObjectType, Cap
from icedl.component.elf import ElfComponent
from icedl.utils import BLOCK_SIZE, PAGE_SIZE

HACK_AFFINITY = 2 # HACK

class Caput(ElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, affinity=HACK_AFFINITY, max_prio=255, update_guard_size=False, **kwargs)

        # HACK
        root_cnode_size_bits = 14
        self.cspace().cnode.size_bits = root_cnode_size_bits

        # FORBIDDEN HACK
        hack_guard_size = self.composition.arch.word_size_bits() - 2*root_cnode_size_bits
        self.cspace().cnode.slots[0] = Cap(self.cspace().cnode, guard=0, guard_size=hack_guard_size)

        allocator_cnode_size_bits = 18
        allocator_cnode = self.alloc(ObjectType.seL4_CapTableObject, name='allocator_cnode', size_bits=14)

        ut_size_bits = 29
        ut_slot = self.cspace().alloc(self.alloc(ObjectType.seL4_UntypedObject, name='allocator_untyped_0', size_bits=ut_size_bits))
        ut = {
            'slot': ut_slot,
            'size_bits': ut_size_bits,
            'paddr': 0,
            'device': False,
        }

        self.host_ep = self.alloc(ObjectType.seL4_EndpointObject, 'host_ep')
        ctrl_ep = self.alloc(ObjectType.seL4_EndpointObject, 'ctrl_ep')

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

        self._arg = {
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
                    'root': self.cspace().alloc(self.cspace().cnode, write=True),
                    'cptr': self.cspace().alloc(allocator_cnode, write=True),
                    'depth': root_cnode_size_bits,
                },
                'guard': 0,
                'guard_size': 0,
                'slots_size_bits': allocator_cnode_size_bits,
            },
            'untyped': [ut],
            'externs': {
                'ctrl_ep_write': {
                    'ty': 'Endpoint',
                    'cptr': self.cspace().alloc(ctrl_ep, write=True, grantreply=True),
                    },
                },
            'host_ep_read': self.cspace().alloc(self.host_ep, read=True),
            'ctrl_ep_read': self.cspace().alloc(ctrl_ep, read=True),
            }

    def map_host(self, objs):
        self._arg['host_rb'] = self.map_ring_buffer(objs)
        self.primary_thread.tcb['bound_notification'] = Cap(objs.read.nfn, read=True)

    def add_extern(self, ident, ty, cptr):
        self._arg['externs'][ident] = {
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

        add(objs.read.nfn, 'Notification', 'read', 'nfn', read=True)
        add(objs.write.nfn, 'Notification', 'write', 'nfn', write=True)

        for i, obj in enumerate(objs.read.ctrl):
            add_frame(obj, 'read', 'ctrl', i, read=True)
        for i, obj in enumerate(objs.write.ctrl):
            add_frame(obj, 'write', 'ctrl', i, read=True, write=True)
        for i, obj in enumerate(objs.read.data):
            add_frame(obj, 'read', 'data', i, read=True)
        for i, obj in enumerate(objs.write.data):
            add_frame(obj, 'write', 'data', i, read=True, write=True)

    def serialize_arg(self):
        return 'serialize-caput-config'

    def arg_json(self):
        self._arg['timer'] = self.connections['timer']['TimerClient']
        timer = self.connections['timer']['TimerClient']
        self.add_extern('timer_ep_write', 'Endpoint', timer['ep_write'])
        self.add_extern('timer_wait', 'Notification', timer['wait'])
        return self._arg

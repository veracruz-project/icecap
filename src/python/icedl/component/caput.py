from pathlib import Path
from capdl import ObjectType, Cap
from icedl.component.generic import GenericElfComponent
from icedl.utils import BLOCK_SIZE, PAGE_SIZE

HACK_AFFINITY = 2 # HACK

class Caput(GenericElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, affinity=HACK_AFFINITY, **kwargs)

        cnode_size_bits = 18
        self.cspace().cnode.size_bits = cnode_size_bits

        ut_size_bits = 30
        ut_slot = self.cspace().alloc(self.alloc(ObjectType.seL4_UntypedObject, name='{}_foo_untyped'.format(self.name), size_bits=ut_size_bits))

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
            'spec': None,
            'my': {
                'cnode': self.cspace().alloc(self.cspace().cnode, write=True),
                'asid_pool': self.cspace().alloc(self.alloc(ObjectType.seL4_ASID_Pool, 'asid_pool_{}'.format(self.name))),
                'tcb_authority': self.cspace().alloc(self.primary_thread.tcb),
                'pd': self.cspace().alloc(self.pd(), write=True),
                'small_page_addr': small_frame_addr,
                'large_page_addr': large_frame_addr,
                },
            'my_extra': {
                'small_page': small_frame,
                'large_page': large_frame,
                'untyped': ut_slot,
                },
            'externs': {
                'ctrl_ep_write': {
                    'ty': 'Endpoint',
                    'cptr': self.cspace().alloc(ctrl_ep, write=True, grantreply=True),
                    },
                },
            'ctrl_ep_read': self.cspace().alloc(ctrl_ep, read=True),
            }

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

    def map_spec(self):
        self.align(BLOCK_SIZE)
        start = self.cur_vaddr
        end = self.map_file(start, 'spec.ddl', Path(self.config()['spec']))
        self.cur_vaddr = end
        self._arg['spec'] = {
            'start': start,
            'end': end,
            }

    def arg_json(self):
        self._arg['timer'] = self.connections['timer']['TimerClient']
        self._arg['my_extra']['free_slot'] = self.cspace().alloc(None)
        timer = self.connections['timer']['TimerClient']
        self.add_extern('timer_ep_write', 'Endpoint', timer['ep_write'])
        self.add_extern('timer_wait', 'Notification', timer['wait'])
        return self._arg

    def map_host(self, objs, ready_obj=None):
        ready_cap = None
        if ready_obj is not None:
            ready_cap = self.cspace().alloc(ready_obj, read=True)
        self._arg['host'] = {
            'ready_wait': ready_cap,
            'rb': self.map_ring_buffer(objs),
            }

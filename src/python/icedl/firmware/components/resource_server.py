import operator
from pathlib import Path
from capdl import ObjectType, Cap
from icedl.common import ElfComponent
from icedl.utils import BLOCK_SIZE, PAGE_SIZE

HACK_TIMER_BADGE = 0x100 # HACK
HACK_SUBSCRIPTION_BADGE = 0x101 # HACK
HACK_HOST_BULK_REGION_SIZE = 2**21

class ResourceServer(ElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, affinity=0, update_guard_size=False, **kwargs)

        # HACK
        root_cnode_size_bits = 14
        self.cspace().cnode.size_bits = root_cnode_size_bits

        # FORBIDDEN HACK
        hack_guard_size = self.composition.arch.word_size_bits() - 2*root_cnode_size_bits
        self.cspace().cnode.slots[0] = Cap(self.cspace().cnode, guard=0, guard_size=hack_guard_size)

        allocator_cnode_size_bits = 18
        allocator_cnode = self.alloc(ObjectType.seL4_CapTableObject, name='allocator_cnode', size_bits=allocator_cnode_size_bits)
        allocator_cnode_shift = root_cnode_size_bits

        ut_size_bits_spec = [29]
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

        event_server_client =  list(map(operator.itemgetter(0), self.composition.event_server.register_client(self, None, 'ResourceServer')))
        event_server_control = self.composition.event_server.register_control_resource_server(self)

        local = []
        secondary_threads = []
        for i in range(self.composition.num_nodes()):
            if i != 0:
                thread = self.secondary_thread('secondary_thread_{}'.format(i), affinity=i, prio=self.primary_thread.tcb.prio)
                secondary_threads.append(thread.endpoint)
            else:
                thread = self.primary_thread

            thread.tcb['bound_notification'] = Cap(self.bound_notifications[i], read=True)
            self.composition.event_server.register_resource_server_subscription(self.bound_notifications[i], HACK_SUBSCRIPTION_BADGE)

            local.append({
                'endpoint': self.cspace().alloc(self.endpoints[i], read=True),
                'reply_slot': self.cspace().alloc(None),
                'timer_server_client': self.composition.timer_server.connect(self, i, self.bound_notifications[i], HACK_TIMER_BADGE),
                'event_server_client': event_server_client[i],
                'event_server_control': event_server_control[i],
                })

        self.host_bulk_region_size = HACK_HOST_BULK_REGION_SIZE
        self.host_bulk_region_frames = list(self.composition.alloc_region('host_bulk_region', self.host_bulk_region_size))

        self._arg = {
            'lock': self.cspace().alloc(self.alloc(ObjectType.seL4_NotificationObject, name='lock'), read=True, write=True),

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

            'host_bulk_region_start': self.map_region(self.host_bulk_region_frames, read=True),
            'host_bulk_region_size': self.host_bulk_region_size,

            'cnode': self.cspace().alloc(self.cspace().cnode, write=True, update_guard_size=False),
            'local': local,
            'secondary_threads': secondary_threads,
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

        for i, obj in enumerate(objs.read.ctrl):
            add_frame(obj, 'read', 'ctrl', i, read=True, write=True)
        for i, obj in enumerate(objs.write.ctrl):
            add_frame(obj, 'write', 'ctrl', i, read=True, write=True)
        for i, obj in enumerate(objs.read.data):
            add_frame(obj, 'read', 'data', i, read=True)
        for i, obj in enumerate(objs.write.data):
            add_frame(obj, 'write', 'data', i, read=True, write=True)

    def register_host(self, host):
        for ep in self.endpoints:
            yield (host.cspace().alloc(ep, badge=0, write=True, grantreply=True), host.vm.cspace().alloc(ep, badge=1, write=True, grantreply=True))

    def serialize_arg(self):
        return 'serialize-resource-server-config'

    def arg_json(self):
        return self._arg

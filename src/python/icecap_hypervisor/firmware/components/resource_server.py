import operator
from pathlib import Path
from capdl import ObjectType, Cap
from icecap_framework import SimpleRealizer
from icecap_framework.utils import BLOCK_SIZE, PAGE_SIZE

HACK_TIMER_BADGE = 0x100 # HACK
HACK_SUBSCRIPTION_BADGE = 0x101 # HACK
HACK_HOST_BULK_REGION_SIZE = 2**21 + 2**12 # HACK to allow for 2M frame fill + header

class ResourceServer(SimpleRealizer):

    def __init__(self, *args, **kwargs):
        super().__init__(
            *args,
            affinity=0,
            root_cnode_size_bits=14,
            allocator_cnode_size_bits=18,
            ut_size_bits_spec=[29],
            **kwargs,
            )

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

            'realizer': self.realizer_config,

            'host_bulk_region_start': self.map_region(self.host_bulk_region_frames, read=True),
            'host_bulk_region_size': self.host_bulk_region_size,

            'cnode': self.cspace().alloc(self.cspace().cnode, write=True, update_guard_size=False),
            'local': local,
            'secondary_threads': secondary_threads,
            }

    def register_host(self, host):
        for ep in self.endpoints:
            yield (host.cspace().alloc(ep, badge=0, write=True, grantreply=True), host.vm.cspace().alloc(ep, badge=1, write=True, grantreply=True))

    def serialize_arg(self):
        return ('icecap-serialize-builtin-config', 'resource-server')

    def arg_json(self):
        return self._arg

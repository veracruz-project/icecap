from capdl import ObjectType
from icecap_framework import GenericElfComponent
from icecap_framework.utils import PAGE_SIZE_BITS
from icecap_hypervisor.realm import BaseRealmComposition

class Mirage(GenericElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        node_index = 0

        event = self.composition.extern(
            ObjectType.seL4_NotificationObject,
            'realm_{}_nfn_for_core_{}'.format(self.composition.realm_id(), node_index),
            )

        event_server_endpoint = self.composition.extern(
            ObjectType.seL4_EndpointObject,
            'realm_{}_event_server_client_endpoint_{}'.format(self.composition.realm_id(), self.composition.virt_to_phys_node_map(node_index)),
            )

        event_server_bitfield = self.composition.extern(
            ObjectType.seL4_FrameObject,
            'realm_{}_event_bitfield_for_core_{}'.format(self.composition.realm_id(), node_index),
            )

        net_rb = self.composition.extern_ring_buffer('realm_{}_net_ring_buffer'.format(self.composition.realm_id()), size=1<<(21 + 3))

        # con_rb = self.composition.extern_ring_buffer('realm_{}_serial_server_ring_buffer'.format(self.composition.realm_id()), size=4096)
        # con_kick = self.composition.extern(ObjectType.seL4_NotificationObject, 'realm_{}_serial_server_kick'.format(self.composition.realm_id()))

        self._arg = {
            'event': self.cspace().alloc(event, read=True),
            'event_server_endpoint': self.cspace().alloc(event_server_endpoint, write=True, grantreply=True),
            'event_server_bitfield': self.map_region([(event_server_bitfield, PAGE_SIZE_BITS)], read=True, write=True),

            'net_rb': self.map_ring_buffer(net_rb),

            # 'con_rb': self.map_ring_buffer(con_rb),
            # 'con_kick': self.cspace().alloc(con_kick, write=True),

            'passthru': {
                'mac': '00:0a:95:9d:68:16',
                'ip': '192.168.1.2',
                'network': '192.168.1.0/24',
                'gateway': '192.168.1.1',
                },
            }

    def arg_json(self):
        return self._arg

class Composition(BaseRealmComposition):

    def compose(self):
        self.component(Mirage, 'mirage')

Composition.from_env().run()

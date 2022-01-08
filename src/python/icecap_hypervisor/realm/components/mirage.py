from capdl import ObjectType
from icecap_framework import ElfComponent
from icecap_framework.utils import PAGE_SIZE_BITS

class Mirage(ElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        passthru_path = self.config()['passthru']
        with open(passthru_path, 'rb') as f:
            passthru = f.read()

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

        # TODO
        # con_rb = self.composition.extern_ring_buffer('realm_{}_serial_server_ring_buffer'.format(self.composition.realm_id()), size=4096)
        # con_kick = self.composition.extern(ObjectType.seL4_NotificationObject, 'realm_{}_serial_server_kick'.format(self.composition.realm_id()))

        self._arg = {
            'event': self.cspace().alloc(event, read=True),
            'event_server_endpoint': self.cspace().alloc(event_server_endpoint, write=True, grantreply=True),
            'event_server_bitfield': self.map_region([(event_server_bitfield, PAGE_SIZE_BITS)], read=True, write=True),

            'net_rb': self.map_ring_buffer(net_rb),

            # TODO
            # 'con_rb': self.map_ring_buffer(con_rb),
            # 'con_kick': self.cspace().alloc(con_kick, write=True),

            'passthru': list(passthru),
            }

    def arg_json(self):
        return self._arg

    def serialize_arg(self):
        return self.serialize_builtin_arg('mirage')

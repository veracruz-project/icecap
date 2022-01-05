from capdl import ObjectType
from icecap_framework import GenericElfComponent
from icecap_framework.utils import PAGE_SIZE_BITS
from icecap_hypervisor.realm import BaseRealmComposition

class Minimal(GenericElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        node_index = 0

        con_rb = self.composition.extern_ring_buffer('realm_{}_serial_server_ring_buffer'.format(self.composition.realm_id()), size=4096)
        con_kick = self.composition.extern(ObjectType.seL4_NotificationObject, 'realm_{}_serial_server_kick'.format(self.composition.realm_id()))

        self._arg = {
            'con_rb': self.map_ring_buffer(con_rb),
            'con_kick': self.cspace().alloc(con_kick, write=True),
            }

    def arg_json(self):
        return self._arg

class Composition(BaseRealmComposition):

    def compose(self):
        self.component(Minimal, 'minimal')

Composition.from_env().run()

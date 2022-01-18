from pathlib import Path
from capdl import ObjectType
from icecap_framework import BaseComposition, GenericElfComponent, SimpleRealizer
from icecap_framework.utils import BLOCK_SIZE, PAGE_SIZE

class Supercomponent(SimpleRealizer):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, max_prio=1, ut_size_bits_spec=[26], **kwargs)

        self.align(BLOCK_SIZE)
        subsystem_spec_start = self.cur_vaddr
        subsystem_spec_end = self.map_file(subsystem_spec_start, 'subsystem.bin', Path(self.composition.config['subsystem_spec']))
        self.cur_vaddr = subsystem_spec_end

        nfn = self.alloc(ObjectType.seL4_NotificationObject, name='nfn')

        self.add_extern('nfn', 'Notification', self.cspace().alloc(nfn, write=True))

        self._arg = {
            'realizer': self.realizer_config,
            'subsystem_spec': {
                'start': subsystem_spec_start,
                'end': subsystem_spec_end,
                },
            'nfn': self.cspace().alloc(nfn, read=True),
            }

    def arg_json(self):
        return self._arg

    def serialize_arg(self):
        return 'cat'

class Composition(BaseComposition):

    def compose(self):
        self.component(Supercomponent, 'supercomponent')

Composition.from_env().run()

from capdl import ObjectType
from icedl.common import ElfComponent

class BenchmarkServer(ElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, affinity=0, **kwargs)

        self.ep = self.alloc(ObjectType.seL4_EndpointObject, 'ep')

        self._arg = {
            'ep': self.cspace().alloc(self.ep, read=True),
            'self_tcb': self.cspace().alloc(self.primary_thread.tcb, write=True),
            }

    def serialize_arg(self):
        return 'serialize-benchmark-server-config'

    def arg_json(self):
        return self._arg

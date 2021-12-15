from capdl import ObjectType
from icecap_framework import ElfComponent

class BenchmarkServer(ElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, affinity=0, **kwargs)

        self.ep = self.alloc(ObjectType.seL4_EndpointObject, 'ep')

        self._arg = {
            'ep': self.cspace().alloc(self.ep, read=True),
            'self_tcb': self.cspace().alloc(self.primary_thread.tcb, write=True),
            }

    def serialize_arg(self):
        return self.serialize_builtin_arg('benchmark-server')

    def arg_json(self):
        return self._arg

from icecap_framework import *
from icecap_hypervisor.firmware.components.benchmark_server import BenchmarkServer

class Test(GenericElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, affinity=0, **kwargs)

        self._arg = {
            'benchmark_server_ep': self.cspace().alloc(self.composition.benchmark_server.ep, write=True, grantreply=True),
            }

    def arg_json(self):
        return self._arg


class Composition(BaseComposition):

    def compose(self):
        self.benchmark_server = self.component(BenchmarkServer, 'benchmark_server', prio=252)
        self.test = self.component(Test, 'test', prio=100)


Composition.from_env().run()

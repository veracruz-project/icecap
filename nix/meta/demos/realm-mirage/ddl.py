from icecap_framework import *

class Mirage(GenericElfComponent):

    def arg_json(self):
        return {
            'passthru': {
                'mac': '00:0a:95:9d:68:16',
                'ip': '192.168.1.2',
                'network': '192.168.1.0/24',
                'gateway': '192.168.1.1',
            },
        }

class Composition(BaseComposition):

    def compose(self):
        self.component(Mirage, 'mirage')

Composition.from_env().run()

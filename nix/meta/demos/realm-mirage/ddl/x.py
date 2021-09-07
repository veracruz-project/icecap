from icedl.common import *

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

composition = BaseComposition.from_env()

mirage = composition.component(Mirage, 'mirage')

composition.complete()

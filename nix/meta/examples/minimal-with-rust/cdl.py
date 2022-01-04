from icecap_framework import *

class Minimal(ElfComponent):

    def arg_json(self):
        return {
            'x': [1, 2, 3],
        }

    def serialize_arg(self):
        return [self.composition.config['tools']['serialize-minimal-config']]

class Composition(BaseComposition):

    def compose(self):
        self.component(Minimal, 'minimal')

Composition.from_env().run()

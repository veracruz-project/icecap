from icecap_framework import *

class Test(GenericElfComponent):

    def arg_json(self):
        return None

class Composition(BaseComposition):

    def compose(self):
        self.component(Test, 'test')

Composition.from_env().run()

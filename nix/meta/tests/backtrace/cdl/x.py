from icedl.common import *

class Test(GenericElfComponent):

    def arg_json(self):
        return {
            'test': 'foo',
            }

class Composition(BaseComposition):

    def compose(self):
        self.test = self.component(Test, 'test')

Composition.run()

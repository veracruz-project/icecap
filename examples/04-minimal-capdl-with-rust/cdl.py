from icecap_framework import BaseComposition, ElfComponent

class ExampleComponent(ElfComponent):

    def arg_json(self):
        return {
            'x': [1, 2, 3],
        }

    def serialize_arg(self):
        return [self.composition.config['tools']['serialize-example-component-config']]

class Composition(BaseComposition):

    def compose(self):
        self.component(ExampleComponent, 'example_component')

Composition.from_env().run()

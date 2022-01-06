from icecap_framework import BaseComposition, ElfComponent

class ExampleComponent(ElfComponent):

    def arg(self):
        path_base = self.composition.out_dir / '{}_arg'.format(self.name)
        path_bin = path_base.with_suffix('.bin')
        with path_bin.open('wb') as f_bin:
            f_bin.write(b'Hello, CapDL!\n')
        self.composition.register_file(path_bin.name, path_bin)
        return path_bin.name

class Composition(BaseComposition):

    def compose(self):
        self.component(ExampleComponent, 'example_component')

Composition.from_env().run()

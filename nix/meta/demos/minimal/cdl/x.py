from icedl.common import *

class Minimal(ElfComponent):

    def arg(self):
        path_base = self.composition.out_dir / '{}_arg'.format(self.name)
        path_bin = path_base.with_suffix('.bin')
        with path_bin.open('wb') as f_bin:
            f_bin.write(b'example text\n')
        self.composition.register_file(path_bin.name, path_bin)
        return path_bin.name

composition = BaseComposition.from_env()

minimal = composition.component(Minimal, 'minimal')

composition.complete()

import os
import json
import yaml
import shutil
from collections import namedtuple
from pathlib import Path

from capdl import ObjectType, ObjectAllocator, CSpaceAllocator, AddressSpaceAllocator, lookup_architecture, register_object_sizes
from capdl.Allocator import RenderState, Cap, ASIDTableAllocator, BestFitAllocator, RenderState

from icedl.utils import as_, as_list, BLOCK_SIZE, BLOCK_SIZE_BITS, PAGE_SIZE, PAGE_SIZE_BITS

ARCH = 'aarch64'

RingBufferObjects = namedtuple('RingBufferObjects', 'read write')
RingBufferSideObjects = namedtuple('RingBufferSideObjects', 'size ctrl data')

class BaseComposition:

    @classmethod
    def run(cls):
        composition = cls.from_env()
        composition.compose()
        composition.complete()

    @classmethod
    def from_env(cls):
        with open(os.environ['CONFIG']) as f:
            config = json.load(f)
        with open(config['object_sizes']) as f:
            object_sizes = yaml.load(f, Loader=yaml.FullLoader)
        register_object_sizes(object_sizes)
        return cls(out_dir=os.environ['OUT_DIR'], config=config)

    def __init__(self, out_dir, config):
        self.arch = lookup_architecture(ARCH)
        obj_space = ObjectAllocator()
        obj_space.spec.arch = self.arch.capdl_name()
        self.render_state = RenderState(obj_space=obj_space)

        self.out_dir = Path(out_dir)
        self.config = config
        self.plat = config['plat']

        self.components = set()
        self.files = {}

        self._gic_vcpu_frame = None # allocate lazily

    def compose(self):
        raise NotImplementedError

    def register_component(self, component):
        self.components.add(component)

    def component(self, mk, name, *args, **kwargs):
        component = mk(self, name, *args, **kwargs)
        self.register_component(component)
        return component

    def alloc(self, *args, **kwargs):
        return self.obj_space().alloc(*args, **kwargs)

    def obj_space(self):
        return self.render_state.obj_space

    def register_file(self, fname, path):
        self.files[fname] = Path(path)
        return fname

    def get_file(self, fname):
        return self.files[fname]

    def spec(self):
        return self.render_state.obj_space.spec

    def finalize(self):
        for component in self.components:
            component.pre_finalize()
        for component in self.components:
            component.finalize()

    def allocate(self):
        ASIDTableAllocator().allocate(self.render_state.obj_space.spec)

    def write_spec(self):
        (self.out_dir / 'icecap.cdl').write_text(repr(self.spec()))

    def write_links(self):
        d = self.out_dir / 'links'
        shutil.rmtree(d, ignore_errors=True) # HACK
        d.mkdir()
        for fname, path in self.files.items():
            (d / fname).symlink_to(path)

    def complete(self):
        self.finalize()
        self.allocate()
        self.write_spec()
        self.write_links()

    # objects

    def alloc_region(self, tag, region_size):
        if region_size & ((1 << 21) - 1) == 0:
            frame_size_bits = 21
        else:
            assert region_size & ((1 << 12) - 1) == 0
            frame_size_bits = 12
        frame_size = 1 << frame_size_bits
        num_frames = region_size >> frame_size_bits
        for i in range(num_frames):
            yield self.alloc(ObjectType.seL4_FrameObject, '{}_{}'.format(tag, i), size=frame_size), frame_size_bits

    def alloc_ring_buffer_raw(self, a_name, a_size_bits, b_name, b_size_bits):

        ctrl_size_bits = 12

        def mk(x_name, y_name, x_size_bits):
            return RingBufferSideObjects(
                size=1 << x_size_bits,
                ctrl=tuple(self.alloc_region('ring_buffer_ctrl_{}_to_{}'.format(x_name, y_name), 1 << ctrl_size_bits)),
                data=tuple(self.alloc_region('ring_buffer_data_{}_to_{}'.format(x_name, y_name), 1 << x_size_bits)),
            )

        a_to_b = mk(a_name, b_name, a_size_bits)
        b_to_a = mk(b_name, a_name, b_size_bits)

        return a_to_b, b_to_a

    def alloc_ring_buffer(self, a_name, a_size_bits, b_name, b_size_bits):
        a_to_b, b_to_a = self.alloc_ring_buffer_raw(a_name, a_size_bits, b_name, b_size_bits)
        a_objs = RingBufferObjects(write=a_to_b, read=b_to_a)
        b_objs = RingBufferObjects(write=b_to_a, read=a_to_b)
        return a_objs, b_objs

    def create_gic_vcpu_frame(self):
        raise NotImplementedError

    def gic_vcpu_frame(self):
        if self._gic_vcpu_frame is None:
            self._gic_vcpu_frame = self.create_gic_vcpu_frame()
        return self._gic_vcpu_frame

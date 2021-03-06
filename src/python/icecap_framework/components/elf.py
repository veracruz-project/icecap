import json
import subprocess
from pathlib import Path
from elftools.elf.elffile import ELFFile

from capdl import ObjectType, ELF, Cap

from icecap_framework.utils import PAGE_SIZE, BLOCK_SIZE, vaddr_at_block, align_up, mk_fill, as_list
from icecap_framework.components.base import BaseComponent

DEFAULT_STATIC_HEAP_SIZE = 4 * BLOCK_SIZE

DEFAULT_AFFINITY = 0
DEFAULT_PRIO = 128
DEFAULT_MAX_PRIO = 0
DEFAULT_STACK_SIZE = BLOCK_SIZE

class ElfComponent(BaseComponent):

    def __init__(self, composition, name, affinity=DEFAULT_AFFINITY, prio=DEFAULT_PRIO, max_prio=DEFAULT_MAX_PRIO, fault_handler=None, **kwargs):
        super().__init__(composition, name, **kwargs)

        elf_min_fname = '{}.elf'.format(self.name)
        elf_min_path = Path(self.config()['image']['min'])
        elf_full_path = Path(self.config()['image']['full'])
        self.elf_min = ELF(str(elf_min_path), elf_min_fname, self.composition.arch.capdl_name())
        self.elf_full = ELFFile(elf_full_path.open('rb'))
        self.elf_min_path = elf_min_path
        self.elf_full_path = elf_full_path

        self.composition.register_file(elf_min_fname, elf_min_path)

        self.cur_vaddr = vaddr_at_block(2, 0, 0)

        self.fault_handler = fault_handler
        self.primary_thread = self.thread('primary', affinity=affinity, prio=prio, max_prio=max_prio)
        self.secondary_threads = []

    def pre_finalize(self):
        self.runtime_config(self.heap(), self.arg())

    def finalize(self):
        elf_spec = self.elf_min.get_spec(infer_tcb=False, infer_asid=False, pd=self.addr_space().vspace_root, addr_space=self.addr_space())
        self.obj_space().merge(elf_spec, label=self.key)
        super().finalize()

    def align(self, size):
        self.cur_vaddr = ((self.cur_vaddr - 1) | (size - 1)) + 1

    def skip(self, n):
        self.cur_vaddr += n

    def threads(self):
        yield self.primary_thread
        yield from self.secondary_threads

    def num_threads(self):
        return 1 + len(self.secondary_threads)

    def thread(self, *args, **kwargs):
        thread = ElfThread(self, *args, **kwargs)
        self.register_thread(thread)
        return thread

    def secondary_thread(self, name, *args, affinity=None, prio=None, max_prio=None, **kwargs):
        if affinity is None:
            affinity = self.primary_thread.tcb.affinity
        if prio is None:
            prio = self.primary_thread.tcb.prio + 1 # a reasonable default for thin threads
        if max_prio is None:
            max_prio = self.primary_thread.tcb.max_prio
        thread = self.thread(name, *args, alloc_endpoint=True, affinity=affinity, prio=prio, **kwargs)
        self.secondary_threads.append(thread)
        return thread

    def register_thread(self, thread):
        if self.fault_handler is not None:
            self.fault_handler.handle(thread)

    def runtime_config(self, heap_info, arg_bin):
        self.align(PAGE_SIZE)
        config_vaddr = self.cur_vaddr

        config = {
            'common': {
                'heap_info': heap_info,
                'tls_image': tls_image(self.elf_min._elf),
                'arg': {
                    'offset': 0,
                    'size': 0,
                },
                'image_path_offset': 0,
                'print_lock': self.cspace().alloc(
                    self.alloc(ObjectType.seL4_NotificationObject, 'print_lock'),
                    read=True, write=True, badge=1,
                    ),
                'idle_notification': self.cspace().alloc(
                    self.alloc(ObjectType.seL4_NotificationObject, 'idle_notification'),
                    read=True,
                    ),
            },
            'threads': [ thread.get_thread_runtime_config() for thread in self.threads() ],
            'image_path': str(self.elf_full_path),
            'arg': str(self.composition.out_dir / arg_bin),
        }

        path_base = self.composition.out_dir / '{}_config'.format(self.name)
        path_bin = path_base.with_suffix('.bin')
        path_json = path_base.with_suffix('.json')
        with path_json.open('w') as f_json:
            json.dump(config, f_json, indent=4)
        with path_json.open('r') as f_json:
            with path_bin.open('wb') as f_bin:
                subprocess.check_call(['icecap-serialize-runtime-config'], stdin=f_json, stdout=f_bin)

        self.composition.register_file(path_bin.name, path_bin)

        config_blob_size = path_bin.stat().st_size
        for config_offset in range(0, config_blob_size, PAGE_SIZE):
            length = min(PAGE_SIZE, config_blob_size - config_offset)
            fill = mk_fill(0, length, path_bin.name, config_offset)
            vaddr = config_vaddr + config_offset
            self.map_page(vaddr, read=True, label='config', fill=fill)

        for i, thread in enumerate(self.threads()):
            thread.set_component_runtime_config(config_vaddr, i)

    # default
    def arg(self):
        path_base = self.composition.out_dir / '{}_arg'.format(self.name)
        path_bin = path_base.with_suffix('.bin')
        path_json = path_base.with_suffix('.json')
        with path_json.open('w') as f_json:
            json.dump(self.arg_json(), f_json, indent=4)
        with path_json.open('r') as f_json:
            with path_bin.open('wb') as f_bin:
                try:
                    subprocess.check_call(self.serialize_arg(), stdin=f_json, stdout=f_bin)
                except Exception as e:
                    print(path_json)
                    raise e
        self.composition.register_file(path_bin.name, path_bin)
        return path_bin.name

    def empty_arg(self):
        path_base = self.composition.out_dir / '{}_arg'.format(self.name)
        path_bin = path_base.with_suffix('.bin')
        with path_bin.open('wb') as f_bin:
            pass
        self.composition.register_file(path_bin.name, path_bin)
        return path_bin.name

    def arg_json(self):
        raise NotImplementedError()

    def serialize_arg(self):
        raise NotImplementedError()

    def serialize_generic_component_arg(self, ty):
        return ['icecap-serialize-generic-component-config', ty]

    # default
    def heap(self):
        return self.static_heap()

    def static_heap_size(self):
        return self.config().get('heap_size', DEFAULT_STATIC_HEAP_SIZE)

    def static_heap(self):
        start = vaddr_at_block(1, 0, 0)
        size = self.static_heap_size()
        lock = self.cspace().alloc(
                self.alloc(ObjectType.seL4_NotificationObject, 'heap_lock'),
                read=True, write=True, badge=1,
                )
        end = start + size
        self.map_range(start, end, label='heap')
        return {
            'start': start,
            'end': end,
            'lock': lock,
            }

    def map_ring_buffer(self, objs, cached=True):
        return {
            'read': {
                'size': objs.read.size,
                'ctrl': self.map_region(objs.read.ctrl, read=True, write=True, cached=cached),
                'data': self.map_region(objs.read.data, read=True, cached=cached),
                },
            'write': {
                'size': objs.write.size,
                'ctrl': self.map_region(objs.write.ctrl, read=True, write=True, cached=cached),
                'data': self.map_region(objs.write.data, read=True, write=True, cached=cached),
                },
            }

    def map_region(self, region, **perms):
        self.skip(4096)
        self.align(1 << region[0][1]) # HACK
        start = self.cur_vaddr
        vaddr = start
        for frame, size_bits in region:
            assert vaddr & ((1 << size_bits) - 1) == 0
            cap = Cap(frame, **perms)
            self.addr_space().add_hack_page(vaddr, 1 << size_bits, cap)
            vaddr += 1 << size_bits
        self.cur_vaddr = vaddr
        return start


def tls_image(elf):
    tls = None
    for seg in elf.iter_segments():
        if seg.header.p_type == 'PT_TLS':
            assert tls is None
            tls = seg
    return {
        'vaddr': tls.header.p_vaddr,
        'filesz': tls.header.p_filesz,
        'memsz': tls.header.p_memsz,
        'align': tls.header.p_align,
    }

def runtime_config_size(num_threads):
    WORD_SIZE = 8
    COMMON_SIZE = 18 * WORD_SIZE
    THREAD_SIZE = 3 * WORD_SIZE
    return COMMON_SIZE + num_threads * THREAD_SIZE

class ElfThread:

    def __init__(self, component, name,
            stack_size=DEFAULT_STACK_SIZE, prio=DEFAULT_PRIO, max_prio=DEFAULT_MAX_PRIO, affinity=DEFAULT_AFFINITY,
            grant_tcb_cap=True, alloc_endpoint=False,
            ):

        self.component = component
        self.name = name

        self.component.skip(PAGE_SIZE)
        self.component.align(BLOCK_SIZE)
        stack_start_vaddr = self.component.cur_vaddr
        stack_end_vaddr = stack_start_vaddr + stack_size
        ipc_buffer_vaddr = stack_end_vaddr + PAGE_SIZE
        self.component.cur_vaddr = ipc_buffer_vaddr + 2 * PAGE_SIZE
        self.component.map_range(stack_start_vaddr, stack_end_vaddr, label='{}_stack'.format(self.name))
        ipc_buffer_frame = self.component.alloc(ObjectType.seL4_FrameObject, '{}_ipc_buffer'.format(self.name), size=PAGE_SIZE)
        ipc_buffer_cap = Cap(ipc_buffer_frame, read=True, write=True)
        self.component.addr_space().add_hack_page(ipc_buffer_vaddr, PAGE_SIZE, ipc_buffer_cap)

        tcb = self.component.alloc(ObjectType.seL4_TCBObject, name='{}_tcb'.format(self.name))
        tcb.ip = self.component.elf_min.get_entry_point()
        tcb.sp = stack_end_vaddr
        tcb.addr = ipc_buffer_vaddr
        tcb.prio = prio
        tcb.max_prio = max_prio
        tcb.affinity = affinity
        tcb.resume = True
        tcb['cspace'] = self.component.cnode_cap
        tcb['vspace'] = Cap(self.component.pd())
        tcb['ipc_buffer_slot'] = ipc_buffer_cap

        self.tcb = tcb
        self.ipc_buffer_vaddr = ipc_buffer_vaddr

        self.endpoint = 0
        if alloc_endpoint:
            self.endpoint = self.component.cspace().alloc(
                self.component.alloc(ObjectType.seL4_EndpointObject, name='{}_thread_ep'.format(self.name)),
                read=True, write=True,
                )

        self.tcb_cap = 0
        if grant_tcb_cap:
            self.tcb_cap = self.component.cspace().alloc(tcb, name='{}_tcb_cap'.format(self.name))

    def full_name(self):
        return '{}_thread_{}'.format(self.component.name, self.name)

    def get_thread_runtime_config(self):
        return {
            'ipc_buffer': self.ipc_buffer_vaddr,
            'endpoint': self.endpoint,
            'tcb': self.tcb_cap,
            }

    def set_component_runtime_config(self, config_vaddr, thread_index):
        self.tcb.init.append(config_vaddr)
        self.tcb.init.append(thread_index)

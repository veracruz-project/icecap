from capdl import ObjectType, Cap
from icedl.composition import RingBufferObjects, RingBufferSideObjects
from icedl.component.elf import ElfComponent
from icedl.utils import *

DEV_0_IRQ = 209
DEV_0_PADDR = 0x09091000
DEV_0_RING_BUFFER_PADDR_START = 0x80000000

DEV_1_IRQ = 210
DEV_1_PADDR = 0x09092000
DEV_1_RING_BUFFER_PADDR_START = 0x90000000

DEFAULT_IRQ = DEV_0_IRQ
DEFAULT_PADDR = DEV_0_PADDR
DEFAULT_RING_BUFFER_PADDR_START = DEV_0_RING_BUFFER_PADDR_START

CLIENT_RX_BADGE = 1 << 0
CLIENT_TX_BADGE = 1 << 1
IRQ_BADGE = 1 << 2

HACK_AFFINITY = 1 # HACK

class QEMURingBufferServer(ElfComponent):

    def __init__(self, *args, irq=DEFAULT_IRQ, paddr=DEFAULT_PADDR, ring_buffer_paddr_start=DEFAULT_RING_BUFFER_PADDR_START, **kwargs):
        super().__init__(*args, affinity=HACK_AFFINITY, **kwargs)
        self.ring_buffer_paddr_start = ring_buffer_paddr_start

        wait_obj = self.alloc(ObjectType.seL4_NotificationObject, name='{}_wait'.format(self.name))

        self.align(PAGE_SIZE)
        self.skip(PAGE_SIZE)
        dev_vaddr = self.cur_vaddr
        self.map_page(self.cur_vaddr, paddr=paddr, label='qemu_ring_buffer_reg', read=True, write=True, cached=False)
        self.skip(PAGE_SIZE)
        self.skip(PAGE_SIZE)

        self.wait_obj = wait_obj
        self._arg = {
            'irq_handler': self.cspace().alloc(
                self.alloc(ObjectType.seL4_IRQHandler, name='irq_{}'.format(irq), number=irq, notification=Cap(wait_obj, badge=IRQ_BADGE))
                ),
            'dev_vaddr': dev_vaddr,
            'wait': self.cspace().alloc(wait_obj, read=True),
            }

    def connect_raw(self):
        ready_obj = self.alloc(ObjectType.seL4_NotificationObject, name='{}_ready'.format(self.name))
        client_obj = self.alloc(ObjectType.seL4_NotificationObject, name=self.fmt('{}_client'))
        self._arg['ready_signal'] = self.cspace().alloc(ready_obj, write=True)
        self._arg['client_signal'] = self.cspace().alloc(client_obj, write=True, badge=CLIENT_RX_BADGE|CLIENT_TX_BADGE)

        layout = {
            'read': {
                'size': BLOCK_SIZE,
                },
            'write': {
                'size': BLOCK_SIZE,
                },
            }

        paddr = self.ring_buffer_paddr_start

        layout['read']['data'] = paddr
        data_w = [
            (self.alloc(ObjectType.seL4_FrameObject, name=self.fmt('{}_rb_data_r'), paddr=paddr, size=BLOCK_SIZE), BLOCK_SIZE_BITS)
            ]
        paddr += BLOCK_SIZE

        layout['write']['data'] = paddr
        data_r = [
            (self.alloc(ObjectType.seL4_FrameObject, name=self.fmt('{}_rb_data_w'), paddr=paddr, size=BLOCK_SIZE), BLOCK_SIZE_BITS)
            ]
        paddr += BLOCK_SIZE

        layout['read']['ctrl'] = paddr
        ctrl_w = [
            (self.alloc(ObjectType.seL4_FrameObject, name=self.fmt('{}_rb_ctrl_r'), paddr=paddr, size=PAGE_SIZE), PAGE_SIZE_BITS)
            ]
        paddr += PAGE_SIZE

        layout['write']['ctrl'] = paddr
        ctrl_r = [
            (self.alloc(ObjectType.seL4_FrameObject, name=self.fmt('{}_rb_ctrl_w'), paddr=paddr, size=PAGE_SIZE), PAGE_SIZE_BITS)
            ]
        paddr += PAGE_SIZE

        objs = RingBufferObjects(
            read=RingBufferSideObjects(
                nfn=client_obj,
                size=BLOCK_SIZE,
                ctrl=ctrl_r,
                data=data_r,
                ),
            write=RingBufferSideObjects(
                nfn=self.wait_obj,
                size=BLOCK_SIZE,
                ctrl=ctrl_w,
                data=data_w,
                ),
            )

        self._arg['layout'] = layout

        return objs, ready_obj

    def connect(self, client):
        objs, ready_obj = self.connect_raw()
        return {
            'ready_wait': client.cspace().alloc(ready_obj, read=True),
            'rb': client.map_ring_buffer(objs, cached=False),
            }

    def serialize_arg(self):
        return 'serialize-qemu-ring-buffer-server-config'

    def arg_json(self):
        return self._arg


class QEMURingBufferServer_0(QEMURingBufferServer):
    def __init__(self, *args, **kwargs):
        super().__init__(irq=DEV_0_IRQ, paddr=DEV_0_PADDR, ring_buffer_paddr_start=DEV_0_RING_BUFFER_PADDR_START, *args, **kwargs)


class QEMURingBufferServer_1(QEMURingBufferServer):
    def __init__(self, *args, **kwargs):
        super().__init__(irq=DEV_1_IRQ, paddr=DEV_1_PADDR, ring_buffer_paddr_start=DEV_1_RING_BUFFER_PADDR_START, *args, **kwargs)

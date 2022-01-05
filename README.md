# IceCap _(soft launch)_

IceCap is a virtualization platform from [Arm
Research](https://developer.arm.com/solutions/research/research-publications)
with a minimal trusted computing base that aims to provide guests with
confidentiality and integrity guarentees. At the foundation of IceCap is
[seL4](https://sel4.systems/), the formally verified microkernel.

[This seL4 Summit 2020 talk](https://nickspinale.com/talks/sel4-summit-2020.html)
provides a high-level overview of IceCap's design.

Notably, IceCap replaces the C-based seL4 userspace of the
[seL4 software ecosystem](https://github.com/seL4) with Rust. With the
exception of CapDL, IceCap's seL4 userspace contains
[less than 350 lines of C](./src/c/icecap-runtime).

This is a _soft launch_. We are still working on adding documentation to this
repository.  In the meantime, we are eager to share and discuss any aspect of
IceCap's design and implementation with you directly. Please feel free to reach
out to project lead [Nick Spinale &lt;nick.spinale@arm.com&gt;](mailto:nick.spinale@arm.com).

## Quick start

See [./demos/README.md](./demos/README.md) for instructions on how to get a demo up and running.

## Guided introduction

See [./examples/README.md](./examples/README.md) for a guided introduction to the IceCap framework.

## Supported platforms

IceCap supports Armv8.

Note that we intentionally use different platform names than the seL4 kernel.
seL4 has the notion of a `KernelPlatform` (e.g. `bcm2711` for the Raspberry Pi
4). Our platforms may eventually become more specific than those named by seL4.

- `virt`: A minimal, made-up platform emulated by QEMU with `qemu-system-aarch64 -M virt`

- `rpi4`: Raspberry Pi 4 Model B (with =4GiB RAM, see note above)

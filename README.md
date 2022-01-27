# IceCap

[![pipeline status](https://gitlab.com/arm-research/security/icecap/icecap/badges/main/pipeline.svg)](https://gitlab.com/arm-research/security/icecap/icecap/-/commits/main)

IceCap is a virtualization platform from [Arm
Research](https://developer.arm.com/solutions/research/research-publications)
with a minimal trusted computing base that aims to provide guests with
confidentiality and integrity guarentees. IceCap serves as a research vehicle
for virtualization-based confidential computing.  At the foundation of IceCap is
[seL4](https://sel4.systems/), the formally verified microkernel.

[This seL4 Summit 2020 talk](https://nickspinale.com/talks/sel4-summit-2020.html)
provides a high-level overview of IceCap's design.

The IceCap project is logically partitioned into the **IceCap Hypervisor**,
which names the firmware and supporting components which together form the
virtualization platform mentioned above, and the more general **IceCap
Framework**, which is a collection of libraries and tools for constructing
seL4-based systems.  The IceCap Hypervisor is the original purpose of the IceCap
Framework, and remains the reference application of the IceCap Framework. This
repository contains both the IceCap Hypervisor and the IceCap Framework.

##### Highlights

- IceCap Framework replaces the C-based seL4 userspace of the [seL4 software
  ecosystem](https://github.com/seL4) with Rust. With the exception of libsel4
  and the verified CapDL loader, the IceCap Hypervisor's seL4 userspace contains
  [less than 400 lines of C](./src/c/icecap-runtime).
- The IceCap project includes a port of the [MirageOS unikernel](https://mirage.io/) to seL4.
- The build system of the IceCap project is based on [Nix](https://nixos.org/manual/nix/stable/)
  for the sake of hermeticity, configurability, and maintainability.

We are eager to share and discuss any aspect of IceCap's design and
implementation with you directly. Please feel free to reach out to project lead
[Nick Spinale &lt;nick.spinale@arm.com&gt;](mailto:nick.spinale@arm.com).

## Demo

See [./demos/hypervisor-demo/README.md](./demos/hypervisor-demo) for
instructions on how to build and run a demo of the IceCap Hypervisor.

## Tutorial

See [./examples/README.md](./examples) for a tutorial-style introduction to the
IceCap Framework.

## Supported platforms

IceCap supports Armv8.

Note that we intentionally use different platform names than the seL4 kernel.
seL4 has the notion of a `KernelPlatform` (e.g. `bcm2711` for the Raspberry Pi
4). Our platforms may eventually become more specific than those named by seL4.

- `virt`: A minimal, made-up platform emulated by QEMU with `qemu-system-aarch64 -machine virt`

- `rpi4`: Raspberry Pi 4 Model B (with at least 4GiB of RAM)

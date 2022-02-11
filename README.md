# IceCap

[![pipeline status](https://gitlab.com/arm-research/security/icecap/icecap/badges/main/pipeline.svg)](https://gitlab.com/arm-research/security/icecap/icecap/-/commits/main)

IceCap is a virtualization platform with a minimal trusted computing base that
aims to provide guests with confidentiality and integrity guarentees. IceCap
serves as a research vehicle for virtualization-based confidential computing.
At the foundation of IceCap is [seL4](https://sel4.systems/), the formally
verified microkernel.

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

- IceCap Framework supports a Rust-dominant seL4 userspace. With the exception
  of libsel4 and the [CapDL
  loader](https://dl.acm.org/doi/pdf/10.1145/1851276.1851284), the IceCap
  Hypervisor's seL4 userspace contains [less than 400 lines of
  C](./src/c/icecap-runtime).


IceCap was originally conceived by Nick Spinale [&lt;nick@nickspinale.com&gt;](mailto:nick@nickspinale.com),
and is now maintained and developed by [Arm Research](https://developer.arm.com/solutions/research/research-publications).

Feel free to contact us at [&lt;christopher.haster@arm.com&gt;](mailto:christopher.haster@arm.com).

## Build

IceCap now uses the [seL4 build infrastructure](https://docs.sel4.systems/projects/buildsystem/).
You must have the [seL4 build dependencies](https://docs.sel4.systems/HostDependencies).

To build a project, you need to:
- check out the sources using Repo,
- configure a target build using CMake,
- build the project using Ninja.

Use repo to check icecap out from gitlab. Its manifest is located in the icecap/manifest repository.
```
  mkdir iceap
  cd icecap
  repo init -u https://gitlab.com/arm-research/security/icecap/manifest.git
  repo sync
```

Configure a 64-bit arm build directory, with a simulation target to be run by Qemu. QEMU is a generic and open source machine emulator and virtualizer, and can emulate different architectures on different systems.
```
  mkdir build-arm
  cd build-arm 
  ../init-build.sh -DPLATFORM=qemu-arm-virt -DSIMULATION=TRUE 
  ninja
```

The build images are available in build-arm/images, and a script build-arm/simulation that will run Qemu with the correct arguments to run seL4test.

## Supported platforms

IceCap supports Armv8.

Note that we intentionally use different platform names than the seL4 kernel.
seL4 has the notion of a `KernelPlatform` (e.g. `bcm2711` for the Raspberry Pi
4). Our platforms may eventually become more specific than those named by seL4.

- `virt`: A minimal, made-up platform emulated by QEMU with `qemu-system-aarch64 -machine virt`

- `rpi4`: Raspberry Pi 4 Model B (with at least 4GiB of RAM)

## Historical

IceCap was originally developed as a hypervisor by Nick Spinale during his tenure at
Arm research.  Code for that work including the original Nix build system are stored
on tag v0.1.0.

- The build system of the IceCap v0.1.0project is based on [Nix](https://nixos.org/manual/nix/stable/)
  for the sake of hermeticity, configurability, and maintainability.
- The IceCap project includes a port of the [MirageOS unikernel](https://mirage.io/) to seL4.

### Demo

See [./demos/hypervisor/README.md](./demos/hypervisor) for instructions on how
to build and run a demo of the IceCap Hypervisor.

### Tutorial

See [./examples/README.md](./examples) for a tutorial-style introduction to the
IceCap Framework.


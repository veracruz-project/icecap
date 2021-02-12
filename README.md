# IceCap _(soft launch)_

IceCap is a virtualization platform from [Arm
Research](https://developer.arm.com/solutions/research/research-publications)
with a minimal trusted computing base centered around the formally verified
[seL4 microkernel](https://sel4.systems/) that aims to provide guests with
confidentiality and integrity guarentees.

[This seL4 Summit 2020 talk](https://nickspinale.com/talks/sel4-summit-2020.html)
provides a high-level overview of IceCap's design. Aside from the content of
that talk, one notable aspect of this project is its codebase. This project
replaces the C-based seL4 userspace and CMake-based build system of the [seL4
software ecosystem](https://github.com/seL4) with a Rust-based seL4 userspace
and Nix-based build system. With the exception of CapDL, IceCap's seL4 userspace
contains [less than 350 lines of C](./src/c/icecap-runtime).

This is a _soft launch_. We are still working on adding documentation to this
repository.  In the meantime, we are eager to share and discuss any aspect of
IceCap's design and implementation with you directly. Please feel free to reach
out to project lead [Nick Spinale &lt;nick.spinale@arm.com&gt;](mailto:nick.spinale@arm.com).


## Quick Start

The IceCap build system is based on [Nix](https://nixos.org/nix/). A Linux
system with Nix [installed](https://nixos.org/download.html#nix-quick-install)
is the only requirement for building and developing IceCap. If you encounter
problems, please raise an issue or reach out to
[Nick Spinale &lt;nick.spinale@arm.com&gt;](mailto:nick.spinale@arm.com).

First, clone this respository and its submodules:

```bash
$ git clone https://gitlab.com/arm-research/security/icecap/icecap
$ cd icecap
$ git submodule update --init
```

Next, build Nix with bleeding edge features:

```bash
$ pushd hack/nix
$ nix-build
$ popd
```

From now on, use the Nix binaries in `./hack/nix/result/bin`:

```bash
export PATH="$(pwd)/hack/nix/result/bin:$PATH"
```

Note that the initial build of IceCap may take hours and will consume around
20GB of disk space.

Build a minimal seL4 "Hello, World!", and run it on QEMU:

```bash
$ nix-build nix/ -A instances.virt.demos.minimal-root.run # optional: -j$(nproc)
$ ./result/run
# 'ctrl-a x' quits QEMU
```

Build and run a demo where a host virtual machine spawns a confidential virtual
machine called a realm, and then communicates with it via the virtual network:

```bash
$ nix-build nix/ -A instances.virt.demos.realm-vm.run # optional: -j$(nproc)
$ ./result/run
# ... wait for the host VM to boot to a shell ...
# Spawn a VM in a realm (this will take some time on QEMU):
$(host) create-realm file:/dev/rb_caput /spec.bin
# ... wait for the realm VM to boot to a shell ...
# Type '@?' for console multiplexer help.
# The host VM uses virtual console 0, and the realm VM uses virtual console 1.
# Switch to the realm VM virtual console by typing '@1'
# Access the internet from within the real VM via the host VM:
$(realm) curl http://example.com
# 'ctrl-a x' quits QEMU
```


## Supported Platforms

IceCap supports Armv8.

Note that we intentionally use different platform names than the seL4 kernel.
seL4 has the notion of a `KernelPlatform` (e.g. `bcm2711` for the Raspberry Pi
4). Our platforms may eventually become more specific than those named by seL4.

- `virt`: A minimal, made-up platform emulated by QEMU with `qemu-system-aarch64 -M virt`

- `rpi4`: Rasberry Pi 4

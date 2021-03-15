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
$(host) icecap-host-cli file:/dev/rb_caput /spec.bin
# ... wait for the realm VM to boot to a shell ...
# Type '@?' for console multiplexer help.
# The host VM uses virtual console 0, and the realm VM uses virtual console 1.
# Switch to the realm VM virtual console by typing '@1'
# Access the internet from within the real VM via the host VM:
$(realm) curl http://example.com
# 'ctrl-a x' quits QEMU
```

Build and run a demo where a host virtual machine runs alongside a simple
MirageOS unikernel which acts as a TCP echo server, and then communicates with
it via the virtual network:

```bash
$ nix-build nix/ -A instances.virt.demos.mirage.run # optional: -j$(nproc)
$ ./result/run
# ... wait for the host VM to boot to a shell ...
# Interact with the MirageOS unikernel from inside the host VM:
$(host) nc 192.168.1.2 8080
# ... enter some characters followed by a new line...
# 'ctrl-a x' quits QEMU
```

#### Raspberry Pi 4

The following steps to run the MirageOS demo on the Raspberry Pi 4 expand on the
instructions above, and can be adapted to any of the other demos.  Note that we
have only tested on a Raspberry Pi 4 with 4GB of RAM. Some hard-coded physical
address space constants would likely need to be changed to get IceCap running on
a Raspberry Pi 4 with less than 4GB of RAM. Please reach out to [Nick Spinale
&lt;nick.spinale@arm.com&gt;](mailto:nick.spinale@arm.com) if you would like to
work together to do so.

You will need an SD card containing a sufficiently large bootable FAT partition
(1GB should be enough).  Here is one way to set that up:

```bash
$ fdisk /dev/sd<x>
# ... make the first partition 1GB, bootable, and of type 0B ("W95 FAT32") ...
$ mkfs.vfat /dev/sd<x>1 -n icecap-boot
```

You will also need a USB to TTL adapter. Connect this to pins 14 and 15 on the
Pi (see [this image](docs/images/raspberry-pi-4-uart.jpg)), and access it using
a program like GNU Screen. For example:

```bash
$ screen /dev/ttyUSB0 115200
```

Build the demo and copy it to the boot partition of your SD card:

```bash
$ nix-build nix/ -A instances.rpi4.demos.mirage.run
$ ls -l ./result/boot/
# ./result/boot and its subdirectories contain symlinks which are to be resolved
# and copied to the boot partition of your SD card. For example:
$ mkdir -p ./mnt
$ mount /dev/disk/by-label/icecap-boot ./mnt
$ rm -r ./mnt/* || true # remove the old contents of the boot partition
$ cp -rvL ./result/boot/* ./mnt
$ umount ./mnt
```

The entire demo resides in the boot partition. Power up the board and interact
with the demo via serial.

## Supported Platforms

IceCap supports Armv8.

Note that we intentionally use different platform names than the seL4 kernel.
seL4 has the notion of a `KernelPlatform` (e.g. `bcm2711` for the Raspberry Pi
4). Our platforms may eventually become more specific than those named by seL4.

- `virt`: A minimal, made-up platform emulated by QEMU with `qemu-system-aarch64 -M virt`

- `rpi4`: Rasberry Pi 4

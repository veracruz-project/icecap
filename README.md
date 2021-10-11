# IceCap _(soft launch)_

IceCap is a virtualization platform from [Arm
Research](https://developer.arm.com/solutions/research/research-publications)
with a minimal trusted computing base that aims to provide guests with
confidentiality and integrity guarentees. At the foundation of IceCap is
[seL4](https://sel4.systems/), the formally verified microkernel.

[This seL4 Summit 2020 talk](https://nickspinale.com/talks/sel4-summit-2020.html)
provides a high-level overview of IceCap's design.

Notably, IceCap replaces the C-based seL4 userspace and CMake-based build system
of the [seL4 software ecosystem](https://github.com/seL4) with a Rust-based seL4
userspace and Nix-based build system. With the exception of CapDL, IceCap's seL4
userspace contains [less than 350 lines of C](./src/c/icecap-runtime).

This is a _soft launch_. We are still working on adding documentation to this
repository.  In the meantime, we are eager to share and discuss any aspect of
IceCap's design and implementation with you directly. Please feel free to reach
out to project lead [Nick Spinale &lt;nick.spinale@arm.com&gt;](mailto:nick.spinale@arm.com).


## Quick Start

The easiest way to start building and hacking on IceCap is using Docker. If you
encounter problems, please raise an issue or reach out to [Nick Spinale
&lt;nick.spinale@arm.com&gt;](mailto:nick.spinale@arm.com).

First, clone this respository and its submodules:

```
git clone --recursive https://gitlab.com/arm-research/security/icecap/icecap
cd icecap
```

Next, build, run, and enter a Docker container for development:

```
make -C docker run && make -C docker exec
```

Finally, build and run a demo emulated by QEMU (`-M virt`) where a host virtual
machine spawns a confidential virtual machine called a realm, and then
communicates with it via the virtual network:

```
   [container] make demo
   [container] ./out/demo/run

               # ... wait for the host VM to boot to a shell ...

               # Spawn a VM in a realm:

 [icecap host] icecap-host create 0 /spec.bin && taskset 0x2 icecap-host run 0 0

               # ... wait for the realm VM to boot to a shell ...
               
               # Type '<enter>@?<enter>' for console multiplexer help.
               # The host VM uses virtual console 0, and the realm VM uses virtual console 1.
               # Switch to the realm VM virtual console by typing '<enter>@1<enter>'.
               # Access the internet from within the real VM via the host VM:

[icecap realm] curl http://example.com

               # Switch back to the host VM virtual console by typing '<enter>@0<enter>'.
               # Interrupt the realm's execution with '<ctrl>-c' and then destroy it:

 [icecap host] icecap-host destroy 0
 
               # '<ctrl>-a x' quits QEMU
```

If you want to build IceCap without Docker, the only requirement is
[Nix](https://nixos.org/manual/nix/stable/).  IceCap depends on features
currently present only in unstable versions of Nix since `2.4pre20200407`.  Here
are a few ways to use such a version:

- You could use
  [https://github.com/nspin/minimally-invasive-nix-installer/](https://github.com/nspin/minimally-invasive-nix-installer/).
  This is what the Docker solution uses.
- If you are using NixOS, you could set `nix.package = pkgs.nixUnstable`.
- If you already have Nix installed, you could use the output of `nix-build
  ./nixpkgs -A nixUnstable`. However, if your Nix installation is multi-user,
  then beware that a version mismatch between your Nix frontend and daemon can
  cause problems for some version combinations.

#### Raspberry Pi 4

The following steps to run the demo on the Raspberry Pi 4 expand on the
instructions above.  Note that we have only tested on a Raspberry Pi 4 Model B
with 4GiB of RAM. Some hard-coded physical address space constants would likely
need to be made configurable to get IceCap running on a Raspberry Pi 4 Model B
with an amout of RAM other than 4GiB.  Please reach out to [Nick Spinale
&lt;nick.spinale@arm.com&gt;](mailto:nick.spinale@arm.com) if you would like to
work together to do so.

You will need an SD card containing a sufficiently large bootable FAT partition
(>=1GiB).  Here is one way to set that up:

```
dev_node=sdz # example
fdisk /dev/${dev_node}

# ... make the first partition at least 1GiB, bootable, and of type 0B or 0C (FAT32) ...

mkfs.vfat /dev/${dev_node}1 -n ICECAP_BOOT
```

You will also need a USB to TTL adapter. Connect this to pins 14 and 15 on the
Pi (see [this image](docs/images/raspberry-pi-4-uart.jpg)), and access it using
a program like GNU Screen. For example:

```
screen /dev/ttyUSB0 115200
```

Build the demo and copy it to the boot partition of your SD card:

```
make demo PLAT=rpi4

# ./out/demo/boot and its subdirectories contain symlinks which are to be resolved
# and copied to the boot partition of your SD card. For example:

mount /dev/disk/by-label/ICECAP_BOOT mnt/
cp -rLv out/demo/boot/* mnt/ # even better: rsync -rLv --checksum --delete out/demo/boot/ mnt/
umount mnt/
```

The entire demo resides in the boot partition. Power up the board and interact
with the demo via serial.

Note that, if you are running Nix inside of a Docker container, you will have to
resolve those links and copy them onto the SD card some other way. For example,
you could use the IceCap source directory, which is shared between the container
and the rest of the system, as a buffer. Alternatively, you could run something
like this from outside of the container:

```
container_name=icecap_stateful
rsync -rLv --checksum --delete -e 'docker exec -i' $container_name:/icecap/out/demo/boot/ mnt/
```


## Supported Platforms

IceCap supports Armv8.

Note that we intentionally use different platform names than the seL4 kernel.
seL4 has the notion of a `KernelPlatform` (e.g. `bcm2711` for the Raspberry Pi
4). Our platforms may eventually become more specific than those named by seL4.

- `virt`: A minimal, made-up platform emulated by QEMU with `qemu-system-aarch64 -M virt`

- `rpi4`: Raspberry Pi 4 Model B (with =4GiB RAM, see note above)

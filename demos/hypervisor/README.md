# Demo: IceCap Hypervisor

This is a self-contained guide for quickly building and running a demonstration
of the IceCap Hypervisor, targeting either a QEMU emulation or the Raspberry Pi
4. The only develoment environment requirement is Docker.

First, clone this respository and its submodules:

```
git clone --recursive https://gitlab.com/arm-research/security/icecap/icecap
cd icecap
```

Next, build, run, and enter a Docker container for development:

```
make -C docker/ run && make -C docker/ exec
```

Finally, build and run a demo emulated by QEMU (`-M virt`) where a host virtual
machine spawns a confidential virtual machine called a realm, and then
communicates with it via the virtual network:

```
   [container] cd demos/hypervisor # this directory
   [container] make run

               # ... wait for the host VM to boot to a shell ...

               # Spawn a VM in a realm:

 [icecap host] icecap-host create 0 /vm-realm-spec.bin && taskset 0x2 icecap-host run 0 0

               # ... wait for the realm VM to boot to a shell ...

               # Type '<enter>@?<enter>' for console multiplexer help.
               # The host VM uses virtual console 0, and the realm VM uses virtual console 1.
               # Switch to the realm VM virtual console by typing '<enter>@1<enter>'.
               # Access the internet from within the real VM via the host VM:

[icecap realm] curl http://example.com

               # Switch back to the host VM virtual console by typing '<enter>@0<enter>'.
               # Interrupt the realm's execution with '<ctrl>-c' and then destroy it:

 [icecap host] icecap-host destroy 0

               # Spawn and background a MirageOS unikernel running a TCP echo server in a realm:

 [icecap host] icecap-host create 0 /mirage-realm-spec.bin && taskset 0x2 icecap-host run 0 0 &

               # Communicate with the echo server:

 [icecap host] echo "Hello, World!" | nc 192.168.1.2 8080

               # Cease the realm's exectution and destroy it:

 [icecap host] kill %% && icecap-host destroy 0

               # '<ctrl>-a x' quits QEMU
```

#### Raspberry Pi 4

The following steps to run the demo on the Raspberry Pi 4 expand on the
instructions above.  Note that we have only tested on a Raspberry Pi 4 Model B
with 4GiB of RAM. Some hard-coded physical address space constants would likely
need to be made configurable to get IceCap running on a Raspberry Pi 4 Model B
with an amout of RAM other than 4GiB.

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
make build PLAT=rpi4

# ./out/demo/boot and its subdirectories contain symlinks which are to be resolved
# and copied to the boot partition of your SD card. For example:

mount /dev/disk/by-label/ICECAP_BOOT mnt/
cp -rLv out/demo/boot/* mnt/ # even better: rsync -rLv --checksum --delete out/demo/boot/ mnt/
umount mnt/
```

The entire demo resides in the boot partition. Power up the board and interact
with the demo via serial.

Note that, if you are building inside of a Docker container, you will have to
resolve those links and copy them onto the SD card some other way. For example,
you could use the IceCap source directory, which is shared between the container
and the rest of the system, as a buffer. Alternatively, you could run something
like this from outside of the container:

```
container_name=icecap
rsync -rLv --checksum --delete -e 'docker exec -i' $container_name:/icecap/out/demo/boot/ mnt/
```

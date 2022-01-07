# Guided introduction

```
UNDER CONSTRUCTION

For now, check out the examples in this directory.
```

This is a guided, interactive introduction to the IceCap Framework. It will lead you through the layers of the framework with the help of the example systems in this directory. If you encounter problems or have questions of any kind, please raise an issue or reach out to [Nick Spinale &lt;nick.spinale@arm.com&gt;](mailto:nick.spinale@arm.com).

### Prerequisites

This document assumes that the reader is familiar with [seL4](https://sel4.systems/) kernel API, or at least has the excellent [seL4 Reference Manual](https://sel4.systems/Info/Docs/seL4-manual-latest.pdf) handy.

This document does not assume that the reader is familiar with Nix, but the reader would benefit from having the [Nix manual](https://nixos.org/manual/nix/stable/) handy.

### Development environment

The easiest way to get started building and hacking on IceCap is with Docker.
If you want to build IceCap without Docker, the only requirement is [Nix](https://nixos.org/manual/nix/stable/). See [Building without Docker](../docs/building-without-docker.md) for more information.
If you want to incorporate IceCap into a build system without Nix, see [Building without Nix](../docs/building-without-nix.md).

First, clone this respository and its submodules:

```
git clone --recursive https://gitlab.com/arm-research/security/icecap/icecap
cd icecap
```

Next, build, run, and enter a Docker container for development:

```
make -C docker/ run && make -C docker/ exec
```

This docker container is effectively stateless. All of the build system's state lives in a Docker volume. Consequentially, you can destroy the container, modify the Dockerfile, rebuild the image, and re-run it without losing cached IceCap build artifacts.

### Our first system

Our first system has consists only of a trivial root task: hello world, in C.
Here is the source: [`./01-minimal-root/root-task/src/main.c`](./01-minimal-root/root-task/src/main.c).

The example systems in the guide are configured for `qemu-system-aarch64 -machine virt`.
Each example system is accompanied by a build target which builds the system and creates a convenient shell script to run it emulate it.

To build the first system, run the following from the repository root:

```
nix-build examples/ -A minimal-root.run
```

The Docker image is configured to support tab-completion for Nix attribute paths. For example, try `nix-build examples/ -A minimal-root.<tab>`. `minimal-root.run`, for example, corresponds to the attribute found at [./01-minimal-root/default.nix#L10](./01-minimal-root/default.nix#L10).

Now, run the example:

```
cat ./result/run # take a look
./result/run
# '<ctrl>-a x' quits QEMU
```

The following is the ONLY code compiled into the root task:
- `libsel4`
- [../src/c/icecap-runtime](../src/c/icecap-runtime)
- [../src/c/icecap-utils](../src/c/icecap-utils)

`libicecap-runtime` is a small C runtime, depending only on `libsel4`, which handles everything from `_start` up until `icecap_main`, which is defined in the root task's `main.c`. Note that, in the case of the root task, `libicecap-runtime` is configured with `#define ICECAP_RUNTIME_ROOT` in [../nix/scope/configured/sel4-user/c/default.nix#L85](../nix/scope/configured/sel4-user/c/default.nix#L85). The root task configuration of `libicecap-runtime` is more complicated than the CapDL component configuration, so we will defer our examination of `libicecap-runtime` until we introduce CapDL. 

`libicecap-utils` depends only on `libsel4` and `libicecap-runtime` and contains a few namespaced utilities, such as `icecap_utils_debug_printf`.

##### Using Rust

By writing seL4 components in Rust, we benefit not only from Rust's memory safe and advanced language features, but also the Rust library ecosystem. The IceCap Framework includes a collection of crates for creating seL4 components.
Check out the [rendered rustdoc](https://arm-research.gitlab.io/security/icecap/html/rustdoc/) for the IceCap crates.
[./02-minimal-root-with-rust/root-task/src/main.rs](./02-minimal-root-with-rust/root-task/src/main.rs) is an example of a simple root task, written in Rust, which parses the Flattened Device Tree passed to it by the kernel via the `bootinfo`.

```
nix-build examples/ -A minimal-root-with-rust.run && ./result/run
```

### Leveraging CapDL

```
nix-build examples/ -A minimal-capdl.composition.cdl
cat result/icecap.cdl
ls result/links/
```

```
nix-build examples/ -A minimal-capdl.run && ./result/run
```

##### The IceCap Python libraries

##### Typed component configuration

```
nix-build examples/ -A minimal-capdl-with-rust.run && ./result/run
```

### Putting it all together: A basic componentized system

```
nix-build examples/ -A basic-system.run && ./result/run
```

<!-- TODO suggest just looking at icecap-core -->
<!-- TODO show off more of the icecap-sel4 crate -->
<!-- TODO mention icecap-show-backtrace -->
<!-- TODO minimal dyndl example -->

### Case study: The IceCap Hypervisor

```
nix-build examples/ -A hypervisor.run && ./result/run
```

```
               # ... wait for the host VM to boot to a shell ...

               # Spawn a VM in a realm:

 [icecap host] create vm

               # ... wait for the realm VM to boot to a shell ...
               
               # Type '<enter>@?<enter>' for console multiplexer help.
               # The host VM uses virtual console 0, and the realm VM uses virtual console 1.
               # Switch to the realm VM virtual console by typing '<enter>@1<enter>'.

[icecap realm] echo hello

               # Switch back to the host VM virtual console by typing '<enter>@0<enter>'.
               # Interrupt the realm's execution with '<ctrl>-c' and then destroy it:

 [icecap host] destroy

               # Spawn a MirageOS simple unikernel:

 [icecap host] create mirage

               # Cease the realm's exectution with '<ctrl>-c' and destroy it:

 [icecap host] destroy

               # As usual, '<ctrl>-a x' quits QEMU.
```

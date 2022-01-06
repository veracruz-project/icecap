# Guided introduction

```
UNDER CONSTRUCTION

For now, check out the examples in this directory.
```

This is a guided, interactive introduction to the IceCap Framework. It will lead you through the layers of the framework with the help of the example systems in this directory.
If you encounter problems or have questions of any kind,
please raise an issue or reach out to [Nick Spinale
&lt;nick.spinale@arm.com&gt;](mailto:nick.spinale@arm.com).

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

This docker container is effectively stateless. All of the build system's state lives in a Docker volume. Consequentially, you can destroy the container, modify the Dockerfile, and rebuild and re-run it without losing cached IceCap build artifacts.

### Our first system

<!-- ```
nix-build examples/ -A minimal-root.run
./result/run
``` -->

#### Using Rust

### Leveraging CapDL

#### The IceCap Python libraries

#### Typed component configuration

### A basic componentized system

### Case study: the IceCap Hypervisor

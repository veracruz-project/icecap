# Tutorial

This is an interactive, tutorial-style introduction to the IceCap Framework. It
will lead you through each layer of the framework with the help of the example
systems in this directory. If you encounter problems or have questions of any
kind, please raise an issue or reach out to [Nick Spinale
&lt;nick.spinale@arm.com&gt;](mailto:nick.spinale@arm.com).

### Prerequisites

This guide assumes that the reader is familiar with
[seL4](https://sel4.systems/), or at least has the [seL4 Reference
Manual](https://sel4.systems/Info/Docs/seL4-manual-latest.pdf) handy.

This guide does not assume that the reader is familiar with Nix. You may wish to
refer to the [Nix manual](https://nixos.org/manual/nix/stable/).

### Development environment

The easiest way to get started building and hacking on IceCap is with Docker.
If you want to build IceCap without Docker, the only requirement is
[Nix](https://nixos.org/manual/nix/stable/) (version `>= 2.4`). If you are not
using Docker, see [../docs/hacking.md](../docs/hacking.md) for information about
using our Nix remote cache.  If you want to incorporate IceCap into a build
system without Nix, see [IceCap without Nix](../docs/icecap-without-nix.md).

First, clone this respository and its submodules:

```
git clone --recursive https://gitlab.com/arm-research/security/icecap/icecap
cd icecap
```

Next, build, run, and enter a Docker container for development:

```
make -C docker/ run && make -C docker/ exec
```

If [./docker/Makefile](./docker/Makefile) detects that you are on Linux, then
this Docker container is effectively stateless.  All of the build system's state
lives in a Docker volume.  Consequentially, you can destroy the container,
modify the Dockerfile, rebuild the image, and re-run it without losing cached
IceCap build artifacts.

### Our first system

This system consists only of the seL4 kernel and a trivial root task, written in
C:
[./01-minimal-root-task/root-task/src/main.c](./01-minimal-root-task/root-task/src/main.c).

The example systems in the guide are configured for `qemu-system-aarch64
-machine virt`.  Each example system is accompanied by a build target which
builds the system and creates a shell script to emulate it.

To build, run the following from the root of this repository:

```
nix-build examples/01-minimal-root-task -A run
```

The Docker image is configured to support tab-completion for Nix attribute
paths. For example, try `nix-build examples/01-minimal-root-task -A <tab><tab>`.
The `run` attribute corresponds to the attribute found at
[./01-minimal-root-task/default.nix#L10](./01-minimal-root-task/default.nix#L10).

Now, run the example:

```
cat ./result/run # take a look
./result/run
# '<ctrl>-a x' quits QEMU
```

The following is the only code compiled into the root task:
- `libsel4`
- [../src/c/icecap-runtime](../src/c/icecap-runtime)
- [../src/c/icecap-utils](../src/c/icecap-utils)

`libicecap-runtime` is a small C runtime, depending only on `libsel4`, which is
responsible for `_start` up until `icecap_main`, the latter of which is defined
in the root task's `main.c`. Note that, in the case of the root task,
`libicecap-runtime` is configured with `#define ICECAP_RUNTIME_ROOT` in
[../nix/framework/scope/configured/sel4-user/c/default.nix#L89](../nix/framework/scope/configured/sel4-user/c/default.nix#L89).
The root task configuration of `libicecap-runtime` is more complicated than the
configuration for CapDL components, so we will defer our examination of
`libicecap-runtime` until we introduce CapDL.

`libicecap-utils` depends only on `libsel4` and `libicecap-runtime`, and
contains a few namespaced utilities, such as `icecap_utils_debug_printf`.

### Using Rust

By writing seL4 components in Rust, we benefit not only from Rust's memory safe
and advanced language features, but also the Rust library ecosystem. The IceCap
Framework includes a collection of crates for creating seL4 components.  Check
out the [rendered
rustdoc](https://arm-research.gitlab.io/security/icecap/icecap/rustdoc/) for the
IceCap crates.  The
[icecap-core](https://arm-research.gitlab.io/security/icecap/icecap/rustdoc/worlds/aarch64-icecap/rpi4/host/icecap_core/index.html)
crate is a good place to start.
[./02-minimal-root-task-with-rust/root-task/src/main.rs](./02-minimal-root-task-with-rust/root-task/src/main.rs)
is an example of a simple root task written in Rust.  It parses and prints the
Flattened Device Tree passed to it by the kernel via the `bootinfo`.

```
nix-build examples/02-minimal-root-task-with-rust -A run && ./result/run
```

### Using CapDL

CapDL[[1]](https://dl.acm.org/doi/pdf/10.1145/1851276.1851284)[[2]](https://docs.sel4.systems/projects/capdl/)
(Capability Distribution Language) is a language and set of accompanying tools
for declaratively specifying the state of objects and capabilites of a
seL4-based system.  In this part of the guide, we will be using CapDL to specify
the initial state of our systems.  We will use the
[capdl-loader](https://github.com/seL4/capdl/tree/master/capdl-loader-app) as
the root task, whose only job is to realize the specified state.  This root task
is bundled with a CapDL specification at compile time.

Our first CapDL-based system comprises of only a single component.  That
component, found at
[./03-minimal-capdl/example-component/src/main.c](./03-minimal-capdl/example-component/src/main.c),
is just a simple C program which prints some configuration data passed to it.
Build and run the example, then examine the system's CapDL specification, along
with the files it refers to:

```
nix-build examples/03-minimal-capdl -A run && ./result/run
nix-build examples/03-minimal-capdl -A composition.cdl
cat result/icecap.cdl
ls result/links/
```

Note that `example-component`'s address space is populated not just by
`example_component.elf`, but also by a binary configuration blob called
`example_component_config.bin`.  This blob is a `struct icecap_runtime_config`
(defined in
[../src/c/icecap-runtime/include/icecap-runtime.h](../src/c/icecap-runtime/include/icecap-runtime.h)).
A JSON object roughly corresponding to the value of this blob can be found at
`result/example_component_config.json`:

```
cat result/example_component_config.json
```

As mentioned before, `libicecap-runtime` contains the code which runs between
`_start` and `icecap_main`.  In the case of a CapDL component (as opposed to
when `libicecap-runtime` is compiled for a root task), `ICECAP_RUNTIME_ROOT` is
not defined.  `_start` is defined in
[../src/c/icecap-runtime/src/start.S](../src/c/icecap-runtime/src/start.S).  Go
ahead and mentally trace execution from `_start` to `icecap_main` for the case
where `thread_index == 0`.  The steps are as follows:

- The component begins at `_start` with `x0 <- struct icecap_runtime_config
  *config` and `x1 <- seL4_Word thread_index`.
- `__icecap_runtime_reserve_tls`, defined in `tls.S`, reserves some memory at
  the beginning of the stack of the thread's TLS region and passes control back
  to `runtime.c:__icecap_runtime_continue`.
- The runtime initializes the TLS region.
- Recall that we are only considering the case of the primary thread. The
  primary thread is responsible for moving some configuration values out of the
  `struct icecap_runtime_config` and into symbols that will be accessed by
  application code (e.g. from Rust).
- Finally, the primary thread calls `icecap_main`, which is defined by the
  application.

Application code's interface to the IceCap C runtime
([../src/c/icecap-runtime/include/icecap-runtime.h](../src/c/icecap-runtime/include/icecap-runtime.h))
is comprised of symbols with configuration information (e.g. the location of the
heap, some notification objects for use as static locks, and exception handling
information), and a few functions such as `icecap_runtime_stop_thread()` and
`icecap_runtime_stop_component()`. The crate at
[../src/rust/crates/framework/base/icecap-std](../src/rust/crates/framework/base/icecap-std)
uses this interface to provide a Rust runtime (including, for example,
allocation and exception handling).

### The IceCap Python libraries

This section addresses how the CapDL specification we found at
`examples/03-minimal-capdl -A composition.cdl` was produced.  The IceCap
framework includes a Python library built on top of the [CapDL Python
library](https://github.com/seL4/capdl/tree/master/python-capdl-tool).  This
library is located at
[../src/python/icecap_framework](../src/python/icecap_framework).  To describe a
system, we write a small Python program
([./03-minimal-capdl/cdl.py](./03-minimal-capdl/cdl.py)) using this library
whose input includes the binaries of our components along with some
configuration, and whose output is what you saw at `examples/03-minimal-capdl -A
composition.cdl`.

The IceCap Framework's Nix build system takes care of the details of running
that Python code.  See
[./03-minimal-capdl/default.nix#L16](./03-minimal-capdl/default.nix#L16) for an
example.  For details, either trace the Nix code back to
[../nix/framework/scope/configured/capdl/mk-icedl.nix](../nix/framework/scope/configured/capdl/mk-icedl.nix)
or take a look at the relevant bits of Makefile in the repository referenced in
[IceCap without Nix](../docs/icecap-without-nix.md).

All `class ExampleComponent` in `cdl.py` does is create the file found at
`result/example_component_arg.bin` after `nix-build examples/03-minimal-capdl -A
composition.cdl`.  The contents of this file is embedded into the `struct
icecap_runtime_config` blob passed to the component, and is ultimately the
argument to `void icecap_main(void *arg, seL4_Word arg_size)`.  Recall that this
function is declared in `icecap-runtime.h` and defined by the application.

In the case of `03-minimal-capdl`, that `arg` blob is the text `"Hello,
CapDL!\n"`.  In the manner described just now, that text makes its way from
`cdl.py` to `main.c`.

### Using Rust with CapDL: Typed configuration, threads, and more

Now, let's look at an example where the component is written in Rust, and has
multiple statically declared threads. Build and run the example, and then
prepare to look at its CapDL specification:

```
nix-build examples/04-minimal-capdl-with-rust -A run && ./result/run
nix-build examples/04-minimal-capdl-with-rust -A composition.cdl
ls result/
```

Observe that `main()` defined in
[./04-minimal-capdl-with-rust/example-component/src/main.rs](./04-minimal-capdl-with-rust/example-component/src/main.rs)
takes a value of type `example_component_config::Config`, which is defined in
[./04-minimal-capdl-with-rust/example-component/config/src/lib.rs](./04-minimal-capdl-with-rust/example-component/config/src/lib.rs).
In [./04-minimal-capdl-with-rust/cdl.py](./04-minimal-capdl-with-rust/cdl.py),
we implement `arg_json()` and `serialize_arg()` to create
`result/example_component_arg.bin` which is a serialized blob of type
`example_component_config::Config`. See `result/example_component_arg.json` for
a JSON representation of its value.

This is accomplished by creating a program called
`serialize-example-component-config` (source at
[./04-minimal-capdl-with-rust/example-component/config/cli/src/main.rs](./04-minimal-capdl-with-rust/example-component/config/cli/src/main.rs))
and passing it to our Python code as configuration in
[./04-minimal-capdl-with-rust/default.nix](./04-minimal-capdl-with-rust/default.nix).
Note how the `icecap-config-cli-core` crate handles most of the boilerplate for
us.

Look at the type of
[./04-minimal-capdl-with-rust/example-component/config/src/lib.rs](./04-minimal-capdl-with-rust/example-component/config/src/lib.rs),
along with the value you saw at `example_component_arg.json`. The `Config` type
has both application-specific data (the `"foo"` field) and capability pointers
(e.g. the `"barrier_nfn"` field). Our Python script `cdl.py` declares some seL4
objects with `self.alloc()` and grants capabilities for those objects to the
component with `self.cspace().alloc()`. It passes capability pointers to those
capabilities in the component's capability space to the component application
code via `Config`.

The script also creates a static secondary thread with
`self.secondary_thread()`.  This creates a TCB object and a stack.  At component
boot time, that thread executes from `_start` just like the primary thread, but
it is passed a nonzero `thread_index`.  Eventually it diverges from the primary
thread in `__icecap_runtime_continue()` in
[../src/c/icecap-runtime/src/runtime.c](../src/c/icecap-runtime/src/runtime.c).
It then blocks, waiting for the primary thread to send it a function pointer and
arguments via an associated endpoint.  The `icecap-runtime` crate provides a
high level interface to this low-level mechanism.  The
`example_component_config::Config` field `secondary_thread:
icecap_runtime::Thread` is just a wrapper around `icecap_sel4::Endpoint`.
Observe how the thread is sent a closure in
[./04-minimal-capdl-with-rust/example-component/src/main.rs](./04-minimal-capdl-with-rust/example-component/src/main.rs),

Observe how `cdl.py` also provides `main.rs` with a few seL4 notification
objects which are used for synchronization between the two threads.

### Putting it all together: A basic componentized system

The next example is a CapDL-based system with multiple components:

- [./05-basic-system/components/serial-server](./05-basic-system/components/serial-server):
  Drives the serial device and provides an interface to `application`
- [./05-basic-system/components/timer-server](./05-basic-system/components/timer-server):
  Drives the timer device and provides an interface to `application`
- [./05-basic-system/components/application](./05-basic-system/components/application):
  Prints the time every second, and echos keyboard input

```
nix-build examples/05-basic-system -A run && ./result/run
# wait for the example to boot and then type some characters
```

The Python script for this example is a bit more complex, and is broken up
into several modules: [./05-basic-system/cdl](./05-basic-system/cdl). Note that
the components extend `class GenericElfComponent` rather than `class
ElfComponent`. We forgo build-time type-checking of configuration in this
example for the sake of focus. Everything from the perspective of each
component's `fn main()` is the same as if we were type-checking configuration at
build time.

Our Python script grants `serial-server` and `timer-server` capabilities and
device memory so that they can drive their respective devices. IPC objects and
shared memory connect each to `application`.

Note the use of the `icecap-rpc{-sel4}` crates to pass small Rust values over
the endpoint connecting `application` and `timer-server`.

Take a look at the CapDL specification for this example, and correlate what you
see there with code in the Python script:

```
nix-build examples/05-basic-system -A composition.cdl
find result/
cat result/icecap.cdl
```

The `composition.display` attribute (present in all examples) provides a
breakdown of the system's composition:

```
nix-build examples/05-basic-system -A composition.display
find -L result/
```

### Adding dynamism

So far, we have used CapDL to describe complete, static systems. The IceCap
Framework also includes tools and libraries for creating components which are
capable of dynamically realizing CapDL-like specifications describing subsystems
at runtime. In [./06-dynamism](./06-dynamism), a component called
`supercomponent` is endowed with extra untyped memory resources, and provided
with a serialized CapDL specificaiton called `subsystem`. It uses the `dyndl-*`
crates
([../src/rust/crates/framework/dyndl](../src/rust/crates/framework/dyndl)) to
repeatedly realize and destroy `subsystem`.

```
nix-build examples/06-dynamism -A run && ./result/run
```

Take a look at `subsystem`'s CapDL specification:

```
nix-build examples/06-dynamism -A subsystem
cat result/icecap.cdl
```

You'll notice an object named `extern_nfn`. Objects whose names contain the
prefix `extern_` are treated as special by the `dyndl-realize` crate. Such names
refer to shared objects provided by the realizer. In the case of this example,
`supersystem` and `subsystem` share a notification object, which they use for
communication.

### Case study: The IceCap Hypervisor

The original purpose of the IceCap Framework is the IceCap Hypervisor, a
hypervisor with a minimal trusted computing base which serves as a research
vehicle for virtualization-based confidential computing.  The IceCap Hypervisor
doubles as the reference application of the IceCap Framework.  See
[../README.md](../) for an overview of the IceCap Hypervisor.  This section will
focus on how the IceCap Framework is used to construct the IceCap Hypervisor.

Build and run a simple demonstration of the IceCap Hypervisor, including three
examples of confidential guests (called "Realms").  (For a more sophisticated
demo, see [../demos/hypervisor/README.md](../demos/hypervisor/)).

```
   [container] nix-build examples/07-hypervisor -A run && ./result/run

               # ... wait for the host VM to boot to a shell ...

               # Spawn a minimal Realm:

 [icecap host] create minimal

               # Cease the Realm's exectution with '<ctrl>-c', and then destroy it:

 [icecap host] destroy

               # Spawn a VM in a Realm:

 [icecap host] create vm

               # ... wait for the Realm VM to boot to a shell ...

               # Type '<enter>@?<enter>' for console multiplexer help.
               # The host VM uses virtual console 0, and the Realm VM uses virtual console 1.
               # Switch to the Realm VM virtual console by typing '<enter>@1<enter>'.

[icecap realm] echo hello

               # Switch back to the host VM virtual console by typing '<enter>@0<enter>'.
               # Interrupt the Realm's execution with '<ctrl>-c' and then destroy it:

 [icecap host] destroy

               # Spawn a MirageOS simple unikernel:

 [icecap host] create mirage

               # Cease the Realm's exectution with '<ctrl>-c' and destroy it:

 [icecap host] destroy

               # As usual, '<ctrl>-a x' quits QEMU.
```

The IceCap Hypervisor firmware's structure is similar to that of [Trusted
Firmware-A](https://www.trustedfirmware.org/projects/tf-a/) in that it
initializes the trusted part of the system, and then passes control to a
bootloader in the untrusted part of the system. However, the IceCap Hypervisor
firmware starts in NS-EL2 rather than EL3, and the untrusted domain is confined
to a distinguised virtual machine called the "host", rather than the entire
non-secure world. Take a look at the firmware's CapDL specification and
breakdown:

```
nix-build examples/07-hypervisor -A configured.icecapFirmware.cdl
cat result/icecap.cdl
nix-build examples/07-hypervisor -A configured.icecapFirmware.display
find -L result/
```

For reference, the IceCap Hypervisor's CapDL specification is created with the
an invocation like the following:

```
python3 -m icecap_hypervisor.cli firmware $config -o $out
```

Where `icecap_hypervisor` is the Python module located at
[../src/python/icecap_hypervisor](../src/python/icecap_hypervisor).

The Rust code for the IceCap Hypervisor components is located at
[../src/rust/crates/hypervisor/components](../src/rust/crates/hypervisor/components).

The untrusted bootloader (U-Boot) boots the host virtual machine into a Linux
system, which is responsible for managing the the platform's CPU and memory
resources and for driving the platform's untrusted devices. While the host
manages Realms' CPU and memory resources, it does not have access to those
resources. In other words, the host is responsbile for scheduling and memory
management policy, but the corresponding mechanisms are the responsibility of
trusted services in the hypervisor firmware. These services cooperate
defensively with the host to enable confidential Realm execution.

The host virtual machine spans all cores on the system. "Shadow threads" act as
projections of the Realm's virtual cores onto the host's scheduler, enabling
integration of the resource manager's interface into the host's scheduler with
minimally invasive modifications.

Like the hypervisor itself, Realm images are also specified using CapDL.  Unlike
the hypervisor's CapDL specification, which is realized at boot-time by the root
task, Realm CapDL specifications are realized at Realm creation-time by a
dynamic CapDL loader in the [resource
server](../src/rust/crates/hypervisor/components/resource-server).

Take a look at the CapDL specifications for each of the three example Realms: a
minimal Realm analogous to the `03-minimal-capdl` example, a Linux VM, and a
MirageOS unikernel:

```
nix-build examples/07-hypervisor -A realms.minimal.spec.ddl
nix-build examples/07-hypervisor -A realms.vm.spec.ddl
nix-build examples/07-hypervisor -A realms.mirage.spec.ddl
```

### Case study: Veracruz

Veracruz is a framework for defining and deploying collaborative,
privacy-preserving computations amongst a group of mutually mistrusting
individuals. Veracruz's support for the IceCap Hypervisor serves as another
example application of the IceCap Framework:

[https://github.com/veracruz-project/veracruz](https://github.com/veracruz-project/veracruz)

Veracruz's support for IceCap includes a Realm with a more rich structure than
any presented so far in this guide.  This Realm, called the Veracruz Runtime,
consists of two components: a WebAssembly JIT-compiler and sandbox, and a
supervisor which projects an operating system personality for the sandbox.  The
supervisor manages the virtual address space of the sandbox and provides
services such as `mmap`.

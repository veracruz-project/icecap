{ hostPlatform }:

{ lib, crateUtils
, mk, mkBin, mkLib
, patches
}:

self: with self;

let

  serdeMin = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };

  mkConfigWith = deps: mk {
    deps = [
      icecap-config-common
      icecap-sel4-hack
    ] ++ deps;
    dependencies = {
      serde = serdeMin;
    };
  };

  mkConfig = mkConfigWith [];

in

{
  "icecap" = {

    icecap-backtrace-types = mk {
      dependencies = {
        hex = { version = "*"; default-features = false; };
        pinecone = "*";
        serde = serdeMin;
      };
    };

    icecap-backtrace = mk {
      deps = [
        icecap-backtrace-types
      ];
      dependencies = {
        fallible-iterator = { version = "*"; default-features = false; features = [ "alloc" ]; };
        gimli = { version = "0.20.0"; default-features = false; features = [ "read" ]; };
        log = "*";
      };
    };

    icecap-failure-derive = mk {
      lib.proc-macro = true;
      dependencies = {
        proc-macro2 = "1";
        quote = "1";
        syn = "1.0.3";
        synstructure = "0.12.0";
      };
    };

    icecap-failure = mk {
      deps = [
        icecap-backtrace
        icecap-failure-derive
      ];
      dependencies = {
        log = "*";
        cfg-if = "*";
      };
    };

    icecap-sys = mk {
      buildScript = { icecap-sys-gen }: {
        rustc-env.GEN_RS = icecap-sys-gen;
        rustc-link-lib = [
          "outline" "sel4"
          "icecap_runtime" "icecap_utils" "icecap_pure" # TODO this should be elsewhere
        ];
      };
    };

    icecap-sel4-derive = mk {
      lib.proc-macro = true;
      dependencies = {
        quote = "*";
        syn = "*";
      };
    };

    icecap-sel4-hack-meta = mk {
      dependencies = {
        serde = serdeMin;
      };
    };

    icecap-sel4 = mk {
      deps = [
        icecap-failure
        icecap-sel4-derive
        icecap-sys
      ];
      dependencies = {
        serde = serdeMin;
      };
    };

    icecap-sel4-hack = mk {
      deps = if hostPlatform.system == "aarch64-none" then [
        icecap-sel4
        icecap-runtime
      ] else [
        icecap-sel4-hack-meta
      ];
    };

    icecap-runtime = mk {
      deps = [
        icecap-sel4
      ];
      dependencies = {
        serde = serdeMin;
      };
    };

    icecap-runtime-config = mk {
      dependencies = {
        serde = serdeMin;
      };
    };

    icecap-interfaces = mk {
      deps = [
        icecap-failure
        icecap-sel4
      ];
      dependencies = {
        byteorder = { version = "*"; default-features = false; };
        log = "*";
        register = "*";
      };
    };

    icecap-realize-config = mk {
      deps = [
        icecap-sel4
        icecap-runtime
        icecap-interfaces
        icecap-config-common
      ];
    };

    icecap-vmm = mk {
      deps = [
        icecap-failure
        icecap-sel4
        icecap-interfaces
      ];
      dependencies = {
        num = { version = "*"; default-features = false; };
        register = "*";
        log = "*";
      };
    };

    icecap-net = mk {
      deps = [
        icecap-interfaces
      ];
      dependencies = {
        managed = { version = "*"; default-features = false; features = [ "map" ]; };
        smoltcp = {
          version = "0.6.0";
          default-features = false;
          features = [
            "alloc"
            "log"
            "verbose"
            "ethernet"
            "proto-ipv4"
            "proto-igmp"
            "proto-ipv6"
            "socket-raw"
            "socket-icmp"
            "socket-udp"
            "socket-tcp"
          ];
        };
      };
    };

    icecap-fdt = mk {
      depsPhantom = [
        icecap-failure
      ];
      dependencies = {
        log = "*";
      };
      target."cfg(target_os = \"icecap\")".dependencies = {
        icecap-failure = { path = "../icecap-failure"; };
      };
      target."cfg(not(target_os = \"icecap\"))".dependencies = {
        failure = { version = "*"; };
      };
    };

    icecap-fdt-bindings = mk {
      deps = [
        icecap-fdt
      ];
      depsPhantom = [
        icecap-failure
      ];
      dependencies = {
        log = "*";
        serde = serdeMin;
      };
      target."cfg(target_os = \"icecap\")".dependencies = {
        icecap-failure = { path = "../icecap-failure"; };
      };
      target."cfg(not(target_os = \"icecap\"))".dependencies = {
        failure = { version = "*"; };
      };
    };

    icecap-start = mk {
      deps = [
        icecap-failure
        icecap-sel4
        icecap-runtime
      ];
      dependencies = {
        log = "*"; # TODO
        pinecone = "*";
        serde = serdeMin;
        serde_json = { version = "*"; default-features = false; features = [ "alloc" ]; };
      };
    };

    icecap-core = mk {
      deps = [
        icecap-backtrace
        icecap-failure
        icecap-sys
        icecap-sel4
        icecap-runtime
        icecap-interfaces
        icecap-realize-config
        icecap-config-common
        icecap-start
      ];
    };

    icecap-std = mk {
      deps = [
        icecap-core
      ];
      dependencies = {
        log = "*";
        dlmalloc = { version = "=0.1.3"; };
      };
      propagate = {
        extraManifest = {
          patch.crates-io = {
            dlmalloc.path = patches.dlmalloc.store;
          };
        };
        extraManifestLocal = {
          patch.crates-io = {
            dlmalloc.path = patches.dlmalloc.env;
          };
        };
      };
    };

    icecap-caput-types = mk {
      dependencies = {
        serde = serdeMin;
        pinecone = "*";
      };
    };

    # misc

    generated-module-hack = mk {
      lib.proc-macro = true;
      dependencies = {
        quote = "0.6.11";
        syn = { version = "0.15.26"; features = [ "full" ]; };
      };
    };

    icecap-caput-host = mk {
      deps = [
        icecap-caput-types
      ];
      dependencies = {
      };
    };

  };

  "std-support" = {

    icecap-std-impl = mk {
      dependencies = {
        core = {
          optional = true;
          package = "rustc-std-workspace-core";
          version = "1.0.0";
        };
        compiler_builtins = { version = "0.1.0"; optional = true; };
        # alloc = {
        #   optional = true;
        #   package = "rustc-std-workspace-alloc";
        #   version = "1.0.0";
        # };
      };
      features = {
        rustc-dep-of-std = [
          "core"
          "compiler_builtins/rustc-dep-of-std"
          # "alloc"
        ];
      };
    };

    icecap-std-external = mk {
      deps = [
        icecap-core
      ];
      dependencies = {
        log = "*";
      };
    };

  };

  "components" = {

    fault-handler = mkBin {
      deps = [
        icecap-std
        icecap-fault-handler-config
      ];
    };

    timer-server = mkBin {
      deps = [
        icecap-std
        icecap-timer-server-config
      ];
      dependencies = {
        register = "*";
      };
    };

    serial-server = mkBin {
      deps = [
        icecap-std
        icecap-serial-server-config
      ];
      dependencies = {
        register = "*";
      };
    };

    caput = mkBin {
      deps = [
        icecap-std
        icecap-caput-types
        icecap-qemu-ring-buffer-server-config
        dyndl-types
        dyndl-realize
      ];
      dependencies = {
        pinecone = "*";
        serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
        serde_json = { version = "*"; default-features = false; features = [ "alloc" ]; };
      };
    };

    qemu-ring-buffer-server = mkBin {
      deps = [
        icecap-std
        icecap-qemu-ring-buffer-server-config
      ];
      dependencies = {
        register = "*";
      };
    };

    vmm = mkBin {
      deps = [
        icecap-std
        icecap-vmm-config
        icecap-vmm
      ];
      dependencies = {
        itertools = { version = "*"; default-features = false; };
      };
    };

  };

  "9p" = {

    icecap-p9-wire-format-derive = mk {
      lib.proc-macro = true;
      dependencies = {
        proc-macro2 = "1.0.8";
        quote = "1.0.2";
        syn = "1.0.14";
      };
    };

    icecap-p9 = mk {
      deps = [
        icecap-p9-wire-format-derive
      ];
      dependencies = {
        libc = "*";
      };
      features.trace = [];
    };

    icecap-p9-server-linux = mk {
      deps = [
        icecap-p9
      ];
      dependencies = {
        libc = "*";
      };
      features.trace = [];
    };

    icecap-p9-server-linux-cli = mkBin {
      deps = [
        icecap-p9-server-linux
      ];
      dependencies = {
        getopts = "*";
        libc = "*";
        log = "*";
        env_logger = "*";
      };
    };

  };

  "helpers" = {

    show-backtrace = mkBin {
      deps = [
        icecap-backtrace-types
      ];
      dependencies = {
        addr2line = "0.11.0";
        backtrace = "*";
        clap = "*";
        cpp_demangle = "*";
        fallible-iterator = "*";
        gimli = "0.20.0";
        hex = "*";
        log = "*";
        memmap = "*";
        object = "0.17.*";
        pinecone = "*";
        rustc-demangle = "*";
        serde = "*";
      };
    };

    serialize-dyndl-spec = mkBin {
      deps = [
        dyndl-types
      ];
      dependencies = {
        serde = "*";
        serde_json = "*";
        pinecone = "*";
      };
    };

    serialize-runtime-config = mkBin {
      deps = [
        icecap-runtime-config
      ];
      dependencies = {
        serde = "*";
        serde_json = "*";
      };
    };

    icecap-serialize-config = mk {
      dependencies = {
        serde = "*";
        serde_json = "*";
        pinecone = "*";
      };
    };

    append-icecap-devices = mkBin {
      deps = [
        icecap-fdt
        icecap-fdt-bindings
      ];
      dependencies = {
        serde = "*";
        serde_json = "*";
      };
    };

    create-realm = mkBin {
      deps = [
        icecap-caput-host
      ];
    };

  };

  "config" = {

    icecap-config-common = mk {
      deps = [
        icecap-sel4-hack
      ];
      dependencies = {
        serde = serdeMin;
      };
    };

    icecap-fault-handler-config = mkConfig;
    icecap-timer-server-config = mkConfig;
    icecap-serial-server-config = mkConfig;
    icecap-qemu-ring-buffer-server-config = mkConfig;
    icecap-vmm-config = mkConfig;

  };

  "dyndl" = {

    dyndl-types-derive = mk {
      lib.proc-macro = true;
      dependencies = {
        proc-macro2 = "1";
        quote = "1";
        syn = "1.0.3";
        synstructure = "0.12.0";
      };
    };

    dyndl-types = mk {
      deps = [
        dyndl-types-derive
      ];
      dependencies = {
        serde = serdeMin;
      };
    };

    dyndl-realize = mk {
      deps = [
        dyndl-types
        icecap-core
      ];
      dependencies = {
        serde = serdeMin;
        log = "*";
      };
    };

  };
}

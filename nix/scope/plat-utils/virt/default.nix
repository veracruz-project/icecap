{ lib, runCommand, writeScript, dtc
, devPkgs
, dtb-helpers
}:

let
  vmCores = 4;
  vmMemorySize = 4096 + 1024;

  exe = "${devPkgs.qemu-aarch64}/bin/qemu-system-aarch64";
  exeDtb = exe;
  exeRun = exe;

  frontendArgsWith = extraMachine: [
    "-machine" "virt,virtualization=on${extraMachine},gic-version=2"
    "-cpu" "cortex-a57"
    "-smp" (toString vmCores)
    "-m" (toString vmMemorySize)
    "-nographic"
    "-semihosting-config" "enable=on,target=native"
    "-device" "virtio-net-device,netdev=netdev0"
    "-device" "virtio-9p-device,mount_tag=store,fsdev=store"
  ];

  frontendArgs = frontendArgsWith "";

  dummyBackendArgs = [
    "-netdev" "user,id=netdev0"
    "-fsdev" "local,id=store,security_model=none,readonly,path=."
  ];

  backendArgs = [
    "-serial" "mon:stdio"
    "-serial" "chardev:ss"
    "-serial" "chardev:rb0"
    "-serial" "chardev:rb1"
    "-chardev" "socket,id=ss,host=127.0.0.1,port=5554,server,nowait"
    "-chardev" "socket,id=rb0,host=127.0.0.1,port=5557,server,nowait"
    "-chardev" "socket,id=rb1,host=127.0.0.1,port=5558,server,nowait"
    "-netdev" "user,id=netdev0,hostfwd=tcp::5555-:22,hostfwd=tcp::5556-:80,hostfwd=tcp::5559-:8080"
    "-fsdev" "local,id=store,security_model=none,readonly,path=${builtins.storeDir}"
  ];

  debugArgs = [
    "-s" "-S"
  ];

  dtb = runCommand "virt.dtb" {} ''
    ${exeDtb} ${join (frontendArgsWith ",dumpdtb=$out" ++ dummyBackendArgs)}
  '';

  dts = with dtb-helpers; decompileWithName "virt.dts" dtb;

  cmdPrefix = "${exeRun} ${join (frontendArgs ++ backendArgs)}";

  join = lib.concatStringsSep " ";

  basicScript = { kernel }:
    writeScript "run.sh" ''
      #!${devPkgs.runtimeShell}
      set -eu
      cd "$(dirname "$0")"
      exec ${cmdPrefix} -kernel ${kernel} "$@"
    '';

  basicRun = { firmware, payload, extraLinks ? {} }:
    genericRun {
      inherit payload;
      links = {
        run = basicScript {
          kernel = firmware;
        };
      } // extraLinks;
    };

  devScript = { kernel, extraArgs ? [] }:
    writeScript "run.sh" ''
      #!${devPkgs.runtimeShell}
      set -eu
      cd "$(dirname "$0")"
      debug=
      if [ "$1" = "-d" ]; then
        debug="${join debugArgs}"
      fi
      exec ${cmdPrefix} \
        -d unimp,guest_errors \
        ${join extraArgs} \
        $debug \
        -kernel ${kernel}
    '';

  genericRun = { links, payload }:
    runCommand "run" {} ''
      mkdir $out
      ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
        mkdir -p $out/$(dirname ${k})
        ln -s ${v} $out/${k}
      '') links)}

      mkdir $out/payload
      ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
        ln -s ${v} $out/payload/${k}
      '') payload)}
    '';

  bundle =
    { firmware, payload ? {}
    , extraLinks ? {}
    , platArgs ? {}
    }:

    genericRun {
      inherit payload;
      links = {
        run =
          if platArgs.devScript or false
          then devScript { kernel = firmware; }
          else basicScript { kernel = firmware; };
      } // extraLinks;
    };

in {
  inherit bundle;
  extra = {
    inherit dtb dts;
    # HACK
    inherit cmdPrefix;
  };
}

# TODO
# dtc tool complains about qemu-generated dtb:
# "/cpus/cpu@1: missing enable-method property"

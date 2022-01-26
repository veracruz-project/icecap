{ lib, runCommand, writeScript, dtc
, linuxHelpers
, dtbHelpers
, devPkgs
}:

let
  numCores = 4;
  memorySize = 1024 * 3; # TODO make configurable

  exe = "${devPkgs.linuxHelpers.qemu-aarch64}/bin/qemu-system-aarch64";
  exeDtb = exe;
  exeRun = exe;

  frontendArgsWith = extraMachine: [
    "-machine" "virt,virtualization=on${extraMachine},gic-version=2"
    "-cpu" "cortex-a57"
    "-smp" (toString numCores)
    "-m" (toString memorySize)
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

  backendArgs = { extraNetDevArgs }: [
    "-serial" "mon:stdio"
    "-netdev" "user,id=netdev0,${extraNetDevArgs}"
    "-fsdev" "local,id=store,security_model=none,readonly,path=${builtins.storeDir}"
  ];

    # NOTE
    # example extraNetDevArgs:
    # hostfwd=tcp::5555-:22,hostfwd=tcp::5556-:80,hostfwd=tcp::5559-:8080

    # TODO
    # "-serial" "chardev:ss"
    # "-serial" "chardev:rb0"
    # "-serial" "chardev:rb1"
    # "-chardev" "socket,id=ss,host=127.0.0.1,port=5554,server,nowait"
    # "-chardev" "socket,id=rb0,host=127.0.0.1,port=5557,server,nowait"
    # "-chardev" "socket,id=rb1,host=127.0.0.1,port=5558,server,nowait"

  debugArgs = [
    "-s" "-S"
  ];

  join = lib.concatStringsSep " ";

  dtb = runCommand "virt.dtb" {} ''
    ${exeDtb} ${join (frontendArgsWith ",dumpdtb=$out" ++ dummyBackendArgs)}
  '';

  dts = with dtbHelpers; decompileWithName "virt.dts" dtb;

  cmdPrefix = { extraNetDevArgs ? "" }: "${exeRun} ${join (frontendArgs ++ backendArgs { inherit extraNetDevArgs; })}";

  basicScript = { kernel, extraNetDevArgs, extraQemuArgs }:
    writeScript "run.sh" ''
      #!${devPkgs.runtimeShell}
      set -eu
      cd "$(dirname "$0")"
      exec ${cmdPrefix { inherit extraNetDevArgs; }} -kernel ${kernel} ${extraQemuArgs} "$@"
    '';

  devScript = { kernel, extraNetDevArgs, extraQemuArgs }:
    writeScript "run.sh" ''
      #!${devPkgs.runtimeShell}
      set -eu
      cd "$(dirname "$0")"
      debug=
      if [ "''${1:-}" = "-d" ]; then
        debug="${join debugArgs}"
        shift
      fi
      exec ${cmdPrefix { inherit extraNetDevArgs; }} \
        -d unimp,guest_errors \
        $debug \
        -kernel ${kernel} \
        ${extraQemuArgs} \
        "$@"
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

  elaboratePlatArgs = { devScript ? false, extraNetDevArgs ? "", extraQemuArgs ? "" }: {
    inherit devScript extraNetDevArgs extraQemuArgs;
  };

  bundle =
    { image, payload ? {}
    , extraLinks ? {}
    , platArgs ? {}
    }:
    let
      elaboratedPlatArgs = elaboratePlatArgs platArgs;
    in
      genericRun {
        inherit payload;
        links = {
          run =
            let
              script =
                if elaboratedPlatArgs.devScript
                then devScript
                else basicScript;
            in
              script {
                kernel = image;
                inherit (elaboratedPlatArgs) extraNetDevArgs extraQemuArgs;
              };
        } // extraLinks;
      };

in {
  inherit bundle;
  inherit numCores;
  extra = {
    inherit dtb dts;
    # HACK exposed for firecracker test
    inherit cmdPrefix;
  };
}

# TODO
# dtc tool complains about qemu-generated dtb:
# "/cpus/cpu@1: missing enable-method property"

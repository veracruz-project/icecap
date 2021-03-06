{ lib, writeScript, writeText, linkFarm
, closureInfo

, dtbHelpers
, devPkgs, linuxPkgs
, platUtils

, commonModules

, configured
}:

let
  inherit (linuxPkgs.icecap) linuxKernel nixosLite;
  inherit (configured) icecapPlat selectIceCapPlat;

in

lib.fix (self: with self; {

  host = rec {
    kernel = linuxKernel.host.${icecapPlat}.kernel;
    bootargs = commonBootargs ++ [
      "script=${script}"
      "nr_cpus=3"
    ] ++ lib.optionals (icecapPlat == "virt") [
      "console=ttyAMA0"
    ] ++ lib.optionals (icecapPlat == "rpi4") [
      "earlycon=uart8250,mmio32,0xfe215040"
      "8250.nr_uarts=1"
      "console=ttyS0,115200"
      # NOTE under some circumstances, firmware was silently changing ttyAMA in cmdline.txt to ttyS0 in device tree
    ];
    initramfs = userland.config.build.initramfs;
    userland = nixosLite.eval {
      modules = [
        commonModules
        commonModulesForInstance
        ./host.nix
        {
          instance.plat = icecapPlat;
        }
      ];
    };
  };

  realm = rec {
    kernel = linuxKernel.host.virt.kernel;
    bootargs = commonBootargs ++ [
      "console=ttyS0"
      "reboot=k"
      "panic=1"
      "pci=off"
    ];
    initramfs = userland.config.build.initramfs;
    userland = nixosLite.eval {
      modules = [
        commonModules
        commonModulesForInstance
        ./realm.nix
      ];
    };
  };

  commonModulesForInstance = {
    imports = [
      ./common.nix
    ];
  };

  commonBootargs = [
    "loglevel=7"
    "keep_bootcon"
  ];

  script = linuxPkgs.writeScript "run-test" ''
    #!/bin/sh

    firecracker \
      --no-api \
      --no-seccomp \
      --level Debug \
      --log-path /proc/self/fd/2 \
      --config-file /mnt/${config} \
  '';

  config = linuxPkgs.writeText "config.json" (builtins.toJSON {
    machine-config = {
      vcpu_count = 1;
      mem_size_mib = 512;
    };
    boot-source = {
      kernel_image_path = "/mnt/${realm.kernel}";
      boot_args = "/mnt/${lib.concatStringsSep " " realm.bootargs}";
      initrd_path = "/mnt/${realm.initramfs}";
    };
    drives = [
    ];
    network-interfaces = [
      {
        iface_id = "eth0";
        host_dev_name = "veth0";
      }
    ];
  });

} // lib.optionalAttrs (icecapPlat == "virt") {

  run = linkFarm "run" [
    { name = "run"; path = runScript; }
  ];

  runScript = writeScript "run.sh" (with platUtils.virt.extra; ''
      #!${devPkgs.runtimeShell}
      exec ${cmdPrefix {}} \
        -d unimp,guest_errors \
        -kernel ${host.kernel} \
        -initrd ${host.initramfs} \
        -append '${lib.concatStringsSep " " host.bootargs}'
  '');

} // lib.optionalAttrs (icecapPlat == "rpi4") {

  run = linkFarm "run" [
    { name = "boot"; path = boot; }
  ];

  boot = platUtils.rpi4.extra.bootPartitionLinks {
    payload = linuxPkgs.icecap.uBoot.host.${icecapPlat}.mkDefaultPayload {
      kernel = host.kernel;
      initramfs = host.initramfs;
      bootargs = host.bootargs;
      dtb = dt.b.new;
    };
    extraBootPartitionCommands = ''
      mkdir -p $out/nix/store
      ln -s $(cat ${closure}/store-paths) $out/nix/store
    '';
    script =
      let
        scriptPartition = "mmc 0:1";
        scriptAddr = "0x10070000";
        scriptName = "load-host.script.uimg";
        scriptPath = "payload/${scriptName}";
      in
        writeText "script.txt" ''
          load ${scriptPartition} ${scriptAddr} ${scriptPath}
          source ${scriptAddr}
        '';
  };

  dt = rec {
    s = lib.mapAttrs (lib.const dtbHelpers.decompile) b;
    b = {
      old = "${linuxPkgs.icecap.linuxKernel.host.rpi4.dtbs}/broadcom/bcm2711-rpi-4-b.dtb";
      new = with dtbHelpers; compile (catFiles [ s.old ./rpi4.dtsa ]);
    };
  };

  closure = closureInfo {
    rootPaths = [
      script
    ];
  };

})

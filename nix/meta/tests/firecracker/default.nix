{ lib, buildPackages, runCommand, writeScript, writeText
, virtUtils, icecapPlat
, devPkgs, linuxPkgs

, mkInstance

, rpi4Utils
, dtb-helpers
, closureInfo
, callPackage
}:

lib.fix (self: with self; {

  inherit (linux) host realm;

  linux = callPackage ./linux {
    inherit script;
  };

  script = linuxPkgs.writeScript "run-test" ''
    #!/bin/sh

    firecracker \
      --no-api \
      --no-seccomp \
      --level Debug \
      --log-path /proc/self/fd/2 \
      --config-file /mnt/${config} \
  '';

  config =
    let
    in linuxPkgs.writeText "config.json" ''
      {
        "machine-config": {
          "vcpu_count": 1,
          "mem_size_mib": 512
        },        
        "boot-source": {
          "kernel_image_path": "/mnt/${realm.linuxImage}",
          "boot_args": "/mnt/${lib.concatStringsSep " " realm.bootargs}",
          "initrd_path": "/mnt/${realm.initrd}"
        },
        "drives": [
        ],
        "network-interfaces": [
          {
            "iface_id": "eth0",
            "host_dev_name": "veth0"
          }
        ]
      }
    '';

} // lib.optionalAttrs (icecapPlat == "virt") {

  run = writeScript "run.sh" (with virtUtils; ''
      #!${devPkgs.runtimeShell}
      exec ${cmdPrefix} \
        -d unimp,guest_errors \
        -kernel ${host.linuxImage} \
        -initrd ${host.initrd} \
        -append '${lib.concatStringsSep " " host.bootargs}'
  '');

} // lib.optionalAttrs (icecapPlat == "rpi4") {

  boot = rpi4Utils.bootPartitionLinks {
    payload = linuxPkgs.icecap.uBoot.${icecapPlat}.mkDefaultPayload {
      linuxImage = host.linuxImage;
      initramfs = host.initrd;
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
    b = {
      old = "${linuxPkgs.icecap.linuxKernel.host.rpi4.dtbs}/broadcom/bcm2711-rpi-4-b.dtb";
      new = with dtb-helpers; compile (catFiles [ s.old ./rpi4.dtsa ]);
    };
    s = {
      old = dtb-helpers.decompile b.old;
      new = dtb-helpers.decompile b.new;
    };
  };

  closure = closureInfo {
    rootPaths = [
      script
    ];
  };

})
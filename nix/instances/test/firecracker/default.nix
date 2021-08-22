{ lib, buildPackages, runCommand, writeScript, writeText
, virtUtils, icecapPlat, linuxKernel
, runPkgs, pkgs_linux

, raspbian, fetchzip
, closureInfo
}:

self: with self; {

  inherit (linux) host realm;

  linux = callPackage ./linux {};


  run = writeScript "run.sh" (with virtUtils; ''
      #!${runPkgs.runtimeShell}
      exec ${cmdPrefix} \
        -d unimp,guest_errors \
        -kernel ${host.linuxImage} \
        -initrd ${host.initrd} \
        -append '${lib.concatStringsSep " " host.bootargs}'
  '');

  script = pkgs_linux.writeScript "run-test" ''
    #!/bin/sh

    ip tuntap add veth0 mode tap
    ip address add 192.168.1.1/24 dev veth0
    ip link set veth0 up

    firecracker \
      --no-api \
      --no-seccomp \
      --level Debug \
      --log-path /proc/self/fd/2 \
      --config-file /mnt/${config} \
  '';

  config =
    let
    in pkgs_linux.writeText "config.json" ''
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

  ###

  cmdlineTxt = writeText "cmdline.txt" ''
    ${lib.concatStringsSep " " host.bootargs}
  '';

  configTxt = writeText "config.txt" ''
    enable_uart=1
    arm_64bit=1
    initramfs initrd followkernel
  '';
    # enable_jtag_gpio=1

  z = runCommand "x.gz" {} ''
    gzip ${linuxKernel.host.rpi4.kernel}  -c > $out
  '';

  boot = runCommand "boot" {} ''
    mkdir $out
    ln -s ${raspbian64}/*.* $out
    mkdir $out/overlays
    ln -s ${raspbian64}/overlays/*.* $out/overlays

    rm $out/kernel*.img
    # ln -s ${linuxKernel.baseline.rpi4.kernel} $out/kernel8.img
    # ln -s ${raspbian64}/kernel8.img $out/kernel8.img
    ln -s ${z} $out/kernel8.img
    # ln -s ${raspbian64}/kernel8.img $out/kernel8.img.x

    ln -sf ${configTxt} $out/config.txt
    ln -sf ${cmdlineTxt} $out/cmdline.txt

    ln -s ${host.initrd} $out/initrd

    mkdir -p $out/nix/store
    ln -s $(cat ${closure}/store-paths) $out/nix/store
  '';
    # ln -s ${host.linuxImage} $out/kernel8.img
    # ln -s ${spec} $out/spec.bin

  closure = closureInfo {
    rootPaths = [
      script
    ];
  };

  raspbian64 = raspbian.mkBoot (fetchzip {
    name = "raspbian.img";
    url = "https://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2021-05-28/2021-05-07-raspios-buster-arm64.zip";
    sha256 = "sha256-B5GMCsB9r6YJau+gPdarZL3juF9nkEBxuqS5c+8XCDI=";
    extraPostFetch = ''
      mv $out/2021-05-07-raspios-buster-arm64.img tmp
      rmdir $out
      mv tmp $out
    '';
    passthru = {
      version = "0";
    };
  });

}

{ lib
, icecapPlat
, pkgs_linux
, linuxKernel

, script
}:

with lib;
let

  pkgs = pkgs_linux;
  inherit (pkgs_linux) nixosLite;

in rec {

  commonBootargs = [
      "loglevel=7"
      "keep_bootcon"
  ];

  host = rec {
    linuxImage = linuxKernel.host.${icecapPlat}.kernel;
    bootargs = commonBootargs ++ [
      "script=${script}"
      "nr_cpus=2"
    ] ++ lib.optionals (icecapPlat == "virt") [
      "console=ttyAMA0"
    ] ++ lib.optionals (icecapPlat == "rpi4") [
      "earlycon=uart8250,mmio32,0xfe215040"
      "8250.nr_uarts=1"
      "console=ttyS0,115200"
      # NOTE under some circumstances, firmware was silently changing ttyAMA in cmdline.txt to ttyS0 in device tree
    ];
    initrd = userland.config.build.initramfs;
    userland = nixosLite.mk1Stage {
      modules = [
        ./host.nix
        {
          instance.plat = icecapPlat;
        }
      ];
    };
  };

  realm = rec {
    linuxImage = linuxKernel.host.virt.kernel;
    bootargs = commonBootargs ++ [
      "console=ttyS0"
      "reboot=k"
      "panic=1"
      "pci=off"
    ];
    initrd = userland.config.build.initramfs;
    userland = nixosLite.mk1Stage {
      modules = [
        ./realm.nix
      ];
    };
  };

}

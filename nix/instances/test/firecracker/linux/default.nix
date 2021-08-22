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
  ];

  host = rec {
    linuxImage = linuxKernel.baseline.${icecapPlat}.kernel;
    bootargs = commonBootargs ++ [
      "keep_bootcon"
      "loglevel=7"
      "script=${script}"
      "nr_cpus=2"
    ] ++ lib.optionals (icecapPlat == "virt") [
      "console=ttyAMA0"
    ] ++ lib.optionals (icecapPlat == "rpi4") [
      # "earlycon=pl011,0xfe201000"
      # "console=ttyS0,115200" # NOTE firmware was silently changing ttyAMA in cmdline.txt to ttyS0 in device tree
      # "console=ttyAMA0,115200" # NOTE firmware was silently changing ttyAMA in cmdline.txt to ttyS0 in device tree
      "console=serial0,115200"
      # "console=tty1"
      "elevator=deadline"
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
      "keep_bootcon"
      "console=ttyS0"
      "reboot=k"
      "panic=1"
      "pci=off"
      "loglevel=8"
    ];
    initrd = userland.config.build.initramfs;
    userland = nixosLite.mk1Stage {
      modules = [
        ./realm.nix
      ];
    };
  };

}

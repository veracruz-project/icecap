{ lib, writeText, writeScript
, linuxKernel, uBoot
, icecapPlat, icecapExtraConfig
, pkgs_linux

, spec
}:

with lib;
let

  pkgs = pkgs_linux;
  inherit (pkgs_linux) nixosLite;

in rec {

  commonBootargs = [
    "earlycon=icecap_vmm"
    "console=hvc0"
    "loglevel=7"
  ];

  host = rec {
    bootargs = commonBootargs ++ [
      "spec=${spec}"
    ];
    initrd = nx.config.build.initramfs;
    linuxImage = linuxKernel.host.${icecapPlat}.kernel;
    # linuxImage = ../../../../../../local/linux/arch/arm64/boot/Image;
    # linuxImage = ../../../../../../local/linux-rpi4/arch/arm64/boot/Image;
    nx = nixosLite.mk1Stage {
      modules = [
        (import ./host.nix {
          inherit icecapPlat spec;
        })
      ];
    };
  };

  realm = rec {
    bootargs = commonBootargs ++ [
      "lamekaslr"
    ];
    initrd = nx.config.build.initramfs;
    linuxImage = linuxKernel.guest.kernel;
    # linuxImage = ../../../../../../local/linux/arch/arm64/boot/Image;
    nx = nixosLite.mk1Stage {
      modules = [
        ./realm.nix
      ];
    };
  };

}

{ lib, writeText, writeScript
, linuxKernel
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
    nx = nixosLite.mk1Stage {
      modules = [
        (import ./host.nix {
          inherit icecapPlat spec;
        })
      ];
    };
  };

  realm = rec {
    bootargs = commonBootargs;
    initrd = nx.config.build.initramfs;
    linuxImage = linuxKernel.guest.kernel;
    nx = nixosLite.mk1Stage {
      modules = [
        ./realm.nix
      ];
    };
  };

}

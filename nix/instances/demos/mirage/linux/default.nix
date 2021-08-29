{ lib
, icecapPlat
, pkgs_linux

, spec
}:

with lib;
let

  pkgs = pkgs_linux;
  inherit (pkgs_linux) nixosLite;
  inherit (pkgs_linux.icecap) linuxKernel;

in rec {

  commonBootargs = [
    "earlycon=icecap_vmm"
    "console=hvc0"
    "loglevel=7"
  ];

  host = rec {
    linuxImage = linuxKernel.host.${icecapPlat}.kernel;
    bootargs = commonBootargs ++ [
      "spec=${spec}"
    ];
    initrd = userland.config.build.initramfs;
    userland = nixosLite.eval {
      modules = [
        ./host.nix
        {
          instance.plat = icecapPlat;
          instance.spec = spec;
        }
      ];
    };
  };

}

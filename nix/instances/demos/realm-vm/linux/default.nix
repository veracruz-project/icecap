{ lib
, icecapPlat
, linuxPkgs

, spec
}:

with lib;
let

  pkgs = linuxPkgs;
  inherit (linuxPkgs) nixosLite;
  inherit (linuxPkgs.icecap) linuxKernel;

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

  realm = rec {
    linuxImage = linuxKernel.guest.kernel;
    bootargs = commonBootargs;
    initrd = userland.config.build.initramfs;
    userland = nixosLite.eval {
      modules = [
        ./realm.nix
      ];
    };
  };

}

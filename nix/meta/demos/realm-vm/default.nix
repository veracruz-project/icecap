{ lib, pkgs }:

lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:

let
  inherit (pkgs.none.icecap) platUtils;
  inherit (configured)
    icecapFirmware icecapPlat selectIceCapPlatOr
    mkLinuxRealm;

in rec {

  run = platUtils.${icecapPlat}.bundle {
    firmware = icecapFirmware.image;
    payload = icecapFirmware.mkDefaultPayload {
      linuxImage = pkgs.linux.icecap.linuxKernel.host.${icecapPlat}.kernel;
      initramfs = hostUser.config.build.initramfs;
      bootargs = commonBootargs ++ [
        "spec=${spec}"
      ];
    };
    platArgs = selectIceCapPlatOr {} {
      rpi4 = {
        extraBootPartitionCommands = ''
          ln -s ${spec} $out/spec.bin
        '';
      };
    };
  };

  spec = mkLinuxRealm {
    kernel = pkgs.linux.icecap.linuxKernel.guest.kernel;
    initrd = realmUser.config.build.initramfs;
    bootargs = commonBootargs;
  };

  commonBootargs = [
    "earlycon=icecap_vmm"
    "console=hvc0"
    "loglevel=7"
  ];

  hostUser = pkgs.linux.icecap.nixosLite.eval {
    modules = [
      ./host.nix
      {
        instance.plat = icecapPlat;
        instance.spec = spec;
      }
    ];
  };

  realmUser = pkgs.linux.icecap.nixosLite.eval {
    modules = [
      ./realm.nix
    ];
  };

})

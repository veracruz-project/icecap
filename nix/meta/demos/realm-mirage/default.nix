{ lib, pkgs }:

lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:

let
  inherit (pkgs.none.icecap) platUtils elfUtils icecapSrc;
  inherit (configured)
    icecapFirmware icecapPlat selectIceCapPlatOr
    mkMirageBinary mkDynDLSpec mkIceDL;

in rec {

  run = platUtils.${icecapPlat}.bundle {
    firmware = icecapFirmware.image;
    payload = icecapFirmware.mkDefaultPayload {
      linuxImage = pkgs.linux.icecap.linuxKernel.host.${icecapPlat}.kernel;
      initramfs = hostUser.config.build.initramfs;
      bootargs = [
        "earlycon=icecap_vmm"
        "console=hvc0"
        "loglevel=7"
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

  spec = mkDynDLSpec {
    cdl = "${ddl}/icecap.cdl";
    root = "${ddl}/links";
    extraPassthru = {
      inherit ddl;
    };
  };

  ddl = mkIceDL {
    action.script = icecapSrc.absoluteSplit ./ddl.py;
    config = {
      realm_id = 0;
      num_cores = 1;
      components = {
        mirage.image = elfUtils.split "${mirageBinary}/bin/mirage.elf";
      };
    };
  };

  mirageLibrary = configured.callPackage ./mirage.nix {};
  mirageBinary = mkMirageBinary mirageLibrary;

  hostUser = pkgs.linux.icecap.nixosLite.eval {
    modules = [
      ./host.nix
      {
        instance.plat = icecapPlat;
        instance.spec = spec;
      }
    ];
  };

})

{ lib, pkgs }:

lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:

let
  inherit (pkgs.none.icecap) platUtils elfUtils;
  inherit (configured)
    icecapPlat icecapFirmware
    mkMirageBinary mkDynDLSpec mkIceDL;

in rec {

  run = platUtils.${configured.icecapPlat}.bundle {
    firmware = icecapFirmware.image;
    inherit payload;
    platArgs = {
      rpi4 = {
        extraBootPartitionCommands = ''
          ln -s ${spec} $out/spec.bin
        '';
      };
    }.${icecapPlat} or {};
  };

  payload = pkgs.linux.icecap.uBoot.${icecapPlat}.mkDefaultPayload {
    linuxImage = pkgs.linux.icecap.linuxKernel.host.${icecapPlat}.kernel;
    initramfs = hostUser.config.build.initramfs;
    dtb = icecapFirmware.host-dtb;
    bootargs = [
      "earlycon=icecap_vmm"
      "console=hvc0"
      "loglevel=7"
      "spec=${spec}"
    ];
  };

  spec = mkDynDLSpec {
    cdl = "${ddl}/icecap.cdl";
    root = "${ddl}/links";
    extraPassthru = {
      inherit ddl;
    };
  };

  ddl = mkIceDL {
    src = ./ddl;
    config = {
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

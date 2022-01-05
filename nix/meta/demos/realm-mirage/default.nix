{ lib, pkgs }:

lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:

let
  inherit (pkgs.dev) writeText;
  inherit (pkgs.none.icecap) platUtils elfUtils icecapSrc;
  inherit (configured)
    icecapFirmware icecapPlat selectIceCapPlatOr
    mkMirageRealm;

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

  spec = mkMirageRealm {
    inherit mirageLibrary;
    passthru = writeText "passthru.json" (builtins.toJSON {
      network_config = {
        mac = "00:0a:95:9d:68:16";
        ip = "192.168.1.2";
        network = "192.168.1.0/24";
        gateway = "192.168.1.1";
      };
    });
  };

  mirageLibrary = configured.callPackage ./mirage.nix {};

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

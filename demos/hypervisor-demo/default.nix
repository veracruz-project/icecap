let
  icecap = import ../../.;
  inherit (icecap) lib pkgs;
in

lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:

let
  inherit (pkgs) dev;
  inherit (pkgs.none.icecap) platUtils;
  inherit (configured) icecapFirmware icecapPlat selectIceCapPlatOr mkLinuxRealm;

in rec {

  realms = {
    vm = import ./realms/vm { inherit lib pkgs; };
    mirage =
      if dev.hostPlatform.isx86_64
      then import ./realms/mirage { inherit lib pkgs; }
      else {
        spec = dev.emptyFile;
      };
  };

  run = platUtils.${icecapPlat}.bundle {
    firmware = icecapFirmware.image;
    payload = icecapFirmware.mkDefaultPayload {
      linuxImage = pkgs.linux.icecap.linuxKernel.host.${icecapPlat}.kernel;
      initramfs = hostUser.config.build.initramfs;
      bootargs = [
        "earlycon=icecap_vmm"
        "console=hvc0"
        "loglevel=7"
        "vm-realm-spec=${realms.vm.spec}"
        "mirage-realm-spec=${realms.mirage.spec}"
      ];
    };
    platArgs = selectIceCapPlatOr {} {
      rpi4 = {
        extraBootPartitionCommands = ''
          ln -s ${realms.vm.spec} $out/vm-realm-spec.bin
          ln -s ${realms.mirage.spec} $out/mirage-realm-spec.bin
        '';
      };
    };
  };

  hostUser = pkgs.linux.icecap.nixosLite.eval {
    modules = [
      ./config.nix
      {
        instance.plat = icecapPlat;
      }
    ];
  };


})

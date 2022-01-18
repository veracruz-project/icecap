{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.none.icecap) platUtils;
  inherit (configured) icecapPlat icecapFirmware;

in rec {

  inherit configured; # for convenience

  run = platUtils.${icecapPlat}.bundle {
    firmware = icecapFirmware.image;
    payload = icecapFirmware.mkDefaultPayload {
      kernel = pkgs.linux.icecap.linuxKernel.host.${icecapPlat}.kernel;
      initramfs = hostUser.config.build.initramfs;
      bootargs = [
        "earlycon=icecap_vmm"
        "console=hvc0"
        "loglevel=7"
        "minimal-realm-spec=${realms.minimal.spec}"
        "vm-realm-spec=${realms.vm.spec}"
        "mirage-realm-spec=${realms.mirage.spec}"
      ];
    };
  };

  realms = {
    minimal = import ./realms/01-minimal { inherit lib pkgs; };
    vm = import ./realms/02-vm { inherit lib pkgs; };
    mirage =
      if pkgs.dev.hostPlatform.isx86_64
      then import ./realms/03-mirage { inherit lib pkgs; }
      else {
        spec = pkgs.dev.emptyFile;
      };
  };

  hostUser = pkgs.linux.icecap.nixosLite.eval {
    modules = [
      ({ pkgs, ... }: {
        initramfs.extraUtilsCommands = ''
          copy_bin_and_libs ${pkgs.icecap.icecap-host}/bin/icecap-host
        '';

        initramfs.extraInitCommands = ''
          mount -t debugfs none /sys/kernel/debug/

          mkdir -p /mnt/nix/store
          mount -t 9p -o trans=virtio,version=9p2000.L,ro store /mnt/nix/store/

          copy_spec() {
            name=$1-realm-spec
            spec="$(sed -rn 's,.*'"$name"'=([^ ]*).*,\1,p' /proc/cmdline)"
            (set -x && cp -L "/mnt/$spec" /$name.bin)
          }

          copy_spec minimal
          copy_spec vm
          copy_spec mirage
        '';

        initramfs.profile = ''
          create() {
            name=$1-realm-spec
            icecap-host create 0 /$1-realm-spec.bin && taskset 0x2 icecap-host run 0 0
          }
          destroy() {
            icecap-host destroy 0
          }
        '';
      })
    ];
  };

}

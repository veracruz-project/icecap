{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.none.icecap) platUtils;
  inherit (configured) icecapPlat icecapFirmware;

in rec {

  realms = {
    vm = import ./realms/vm { inherit lib pkgs; };
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
        "vm_spec=${realms.vm.spec}"
      ];
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
            name=$1
            spec="$(sed -rn 's,.*'"$name"'=([^ ]*).*,\1,p' /proc/cmdline)"
            (set -x && cp -L "/mnt/$spec" /$name.bin)
          }

          copy_spec vm_spec
        '';

        initramfs.profile = ''
          create() {
            icecap-host create 0 /$1.bin && taskset 0x2 icecap-host run 0 0
          }
          destroy() {
            icecap-host destroy 0
          }
        '';
      })
    ];
  };

}

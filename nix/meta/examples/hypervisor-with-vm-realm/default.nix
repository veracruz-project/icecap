{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

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
  };

  spec = mkLinuxRealm {
    kernel = pkgs.linux.icecap.linuxKernel.realm.kernel;
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
      ({ pkgs, ... }: {
        initramfs.extraUtilsCommands = ''
          copy_bin_and_libs ${pkgs.icecap.icecap-host}/bin/icecap-host
        '';

        initramfs.extraInitCommands = ''
          mount -t debugfs none /sys/kernel/debug/
          mkdir -p /etc /bin /mnt/nix/store

          mount -t 9p -o trans=virtio,version=9p2000.L,ro store /mnt/nix/store/
          spec="$(sed -rn 's,.*spec=([^ ]*).*,\1,p' /proc/cmdline)"
          echo "cp -L /mnt/$spec /spec.bin..."
          cp -L "/mnt/$spec" /spec.bin
          echo "...done"
        '';

        initramfs.profile = ''
          create() {
            icecap-host create 0 /spec.bin && taskset 0x2 icecap-host run 0 0
          }
          destroy() {
            icecap-host destroy 0
          }
        '';
      })
    ];
  };

  realmUser = pkgs.linux.icecap.nixosLite.eval {
    modules = [
    ];
  };

}

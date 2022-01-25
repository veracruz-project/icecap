{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.instance;

  # testBigFile = "${pkgs.icecap.linuxPkgs.icecap.linuxKernel.host.virt}/vmlinux-5.6.0-rc2";
  testBigFile = pkgs.emptyFile;

in {
  options.instance = {
  };

  config = lib.mkMerge [

    {
      initramfs.extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.ethtool}/bin/ethtool
        copy_bin_and_libs ${pkgs.strace}/bin/strace
      '';

      initramfs.extraInitCommands = mkAfter ''
        echo 2 > /proc/sys/kernel/randomize_va_space
        ulimit -c unlimited

        export realm_affinity=0x2
      '';
    }

    {
      initramfs.profile = ''
        start_realm() {
          echo "starting realm"
          time taskset $realm_affinity icecap-host create 0 /spec.bin && \
            chrt -b 0 taskset $realm_affinity icecap-host run 0 0
        }

        s() {
          while true; do sha256sum /mnt/${testBigFile}; done
        }
      '';
    }
  ];
}

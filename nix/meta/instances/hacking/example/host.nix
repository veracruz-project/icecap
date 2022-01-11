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

      initramfs.extraInitCommands = ''
        echo 2 > /proc/sys/kernel/randomize_va_space
        ulimit -c unlimited
      '';
    }

    {
      initramfs.profile = ''
        s() {
          while true; do sha256sum /mnt/${testBigFile}; done
        }
      '';
    }
  ];
}

{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.instance;

in {
  config = mkMerge [
    {
      instance.rngHack = true;

      initramfs.extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
        copy_bin_and_libs ${pkgs.sysbench}/bin/sysbench
        copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
      '';

      initramfs.extraInitCommands = ''
      '';

      initramfs.profile = ''
      '';
    }
  ];
}

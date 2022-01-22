{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.instance;

in {
  options.instance = {
    autostart.enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkMerge [
    {
      instance.rngHack = true;

      initramfs.extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
        copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
      '';

      initramfs.extraInitCommands = mkAfter ''
      '';
    }
  ];
}

{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.instance;

in {
  options.instance = {
    utlization.enable = mkOption {
      type = types.bool;
      default = false;
    };
    autostart.enable = mkOption {
      type = types.bool;
      default = !cfg.utlization.enable;
    };
    autostart.cpu = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkMerge [
    {
      instance.rngHack = true;

      initramfs.extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
        copy_bin_and_libs ${pkgs.sysbench}/bin/sysbench
        copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
      '';

      initramfs.extraInitCommands = mkAfter ''
        # sysctl -w net.core.busy_poll=50
        # sysctl -w net.core.busy_read=50

        # sysctl -w net.core.netdev_budget=300 # default
        # sysctl -w net.core.netdev_budget=600
        # sysctl -w net.core.netdev_budget=1200

        # sysctl -w net.core.netdev_budget_usecs=2000 # default
        # sysctl -w net.core.netdev_budget_usecs=20000

        # HACK
        rm /dev/*random
        ln -s /dev/zero /dev/urandom
      '';

      initramfs.profile = ''
        cpu_bound() {
          sysbench cpu --cpu-max-prime=20000 --num-threads=1 run
        }
      '';
    }
  ];
}

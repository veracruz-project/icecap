{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.instance;

in {
  options.instance = {
    hasNat = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkMerge [
    {
      initramfs.extraUtilsCommands = ''
      '';

      initramfs.extraInitCommands = mkAfter ''
        # HACK
        . /etc/profile

        ${lib.optionalString cfg.autostart.enable ''
          auto &
        ''}
      '';

      initramfs.profile = ''
        auto() {
          for _ in $(seq 3); do
            echo test_channel > /dev/icecap_channel_host
          done

          ${lib.optionalString cfg.hasNat ''
            test_nat
          ''}

          start_iperf_client
        }

        test_nat() {
          curl -S http://example.com
        }

        start_iperf_client() {
          while true; do
            [ -f /stop ] || \
              chrt -b 0 iperf3 -c ${cfg.misc.net.hostAddr} && cat /proc/interrupts && sleep 10 && \
              chrt -b 0 iperf3 -R -c ${cfg.misc.net.hostAddr} && cat /proc/interrupts && sleep 10 || \
              break;
          done

          # NOTE
          # -c --bidir
          # -c -R
        }

        stop_iperf_client() {
          touch /stop
          pkill iperf3
        }
      '';
    }
  ];
}

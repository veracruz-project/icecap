{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.instance;

in {
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
          ${lib.optionalString cfg.autostart.cpu ''
            for _ in $(seq 2); do
              cpu_bound
              sleep 5
            done
          ''}
          start_iperf_client
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

        run_iperf_server() {
          iperf3 -s -1
        }
      '';
    }
  ];
}

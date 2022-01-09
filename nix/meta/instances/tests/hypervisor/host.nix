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
        export iperf_affinity=0x4
        export realm_affinity=0x2

        # HACK
        . /etc/profile

        ${lib.optionalString cfg.autostart.enable ''
          auto_tests &
        ''}
      '';

      initramfs.profile = ''
        auto_tests() {
          start_realm &

          head -n 3 < /dev/icecap_channel_realm_0

          start_iperf_server
        }

        start_realm() {
          taskset $realm_affinity icecap-host create 0 /spec.bin && \
            chrt -b 0 taskset $realm_affinity icecap-host run 0 0
        }

        destroy_realm() {
          icecap-host destroy 0
        }

        start_iperf_server() {
          chrt -b 0 iperf3 -s > /dev/null
        }

        stop_iperf_server() {
          pkill iperf3
        }
      '';
    }
  ];
}

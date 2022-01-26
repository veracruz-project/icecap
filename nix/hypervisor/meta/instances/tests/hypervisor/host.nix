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
          auto &
        ''}
      '';

      initramfs.profile = ''
        auto() {
          for i in $(seq 2); do
            start_realm &
            echo short > /dev/icecap_channel_realm_0
            response=$(head -n 1 < /dev/icecap_channel_realm_0)
            [ "$response" = "ok short" ]
            run_iperf_server > /dev/null
            stop_and_destroy_realm
          done

          start_realm &

          echo long > /dev/icecap_channel_realm_0
          response=$(head -n 1 < /dev/icecap_channel_realm_0)
          [ "$response" = "ok long" ]

          head -n 3 < /dev/icecap_channel_realm_0

          for i in $(seq 2); do
            run_iperf_server > /dev/null
          done

          echo TEST_PASS
        }

        start_realm() {
          echo "starting realm"
          time taskset $realm_affinity icecap-host create 0 /spec.bin && \
            chrt -b 0 taskset $realm_affinity icecap-host run 0 0
        }

        destroy_realm() {
          echo "destroying realm"
          time icecap-host destroy 0
        }

        stop_and_destroy_realm() {
          pkill icecap-host && destroy_realm
        }

        run_iperf_server() {
          run_iperf_server_once
          run_iperf_server_once
        }

        run_iperf_server_once() {
          chrt -b 0 iperf3 -s -1
        }
      '';
    }
  ];
}

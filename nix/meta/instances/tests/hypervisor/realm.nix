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
          request=$(head -n 1 < /dev/icecap_channel_host)
          if [ "$request" = "short" ]; then
            echo "ok short" > /dev/icecap_channel_host
            run_iperf_client
            while true; do
              sleep 10
            done
          fi

          [ "$request" = "long" ]
          echo "ok long" > /dev/icecap_channel_host

          ${lib.optionalString cfg.hasNat ''
            test_nat
          ''}

          yes test_channel | head -n 3 > /dev/icecap_channel_host

          for _ in $(seq 3); do
            run_iperf_client
          done
        }

        test_nat() {
          curl -S http://example.com
        }

        run_iperf_client() {
          chrt -b 0 iperf3 -c ${cfg.misc.net.hostAddr}
          chrt -b 0 iperf3 -R -c ${cfg.misc.net.hostAddr}
        }
      '';
    }
  ];
}

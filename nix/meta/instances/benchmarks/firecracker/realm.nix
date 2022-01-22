{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.instance;

  virtualIface = "eth0";

in {
  config = {

    net.interfaces.eth0.static = "${cfg.misc.net.realmAddr}/24";

    initramfs.extraInitCommands = mkAfter ''
      echo "nameserver 1.1.1.1" > /etc/resolv.conf
      ip route add default via ${cfg.misc.net.hostAddr} dev ${virtualIface}

      . /etc/profile

      # for _ in $(seq 2); do
      #   realm_cpu
      #   sleep 5
      # done

      start_iperf_client &
    '';

    initramfs.extraUtilsCommands = ''
    '';

    initramfs.profile = ''
      start_iperf_client() {
        while true; do
          [ -f /stop ] || \
            chrt -b 0 iperf3 -c ${cfg.misc.net.hostAddr} && cat /proc/interrupts && sleep 10 && \
            chrt -b 0 iperf3 -R -c ${cfg.misc.net.hostAddr} && cat /proc/interrupts && sleep 10 || \
            break;
        done
        # chrt -b 0 iperf3 -c ${cfg.misc.net.hostAddr}
      }

      stop_iperf_client() {
        touch /stop
        pkill iperf3
      }

      realm_cpu() {
        sysbench cpu --cpu-max-prime=20000 --num-threads=1 run
      }
    '';

  };
}

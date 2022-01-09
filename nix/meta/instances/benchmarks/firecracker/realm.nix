{ pkgs, lib, ... }:

with import ./common.nix;

let
  virtualIface = "eth0";

in {
  config = {

    net.interfaces.eth0.static = "${realmAddr}/24";

    initramfs.extraInitCommands = ''
      echo "nameserver 1.1.1.1" > /etc/resolv.conf
      ip route add default via ${hostAddr} dev ${virtualIface}

      # for _ in $(seq 2); do
      #   realm_cpu
      #   sleep 5
      # done

      start_iperf_client &
    '';

    initramfs.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
      copy_bin_and_libs ${pkgs.sysbench}/bin/sysbench
      copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
      cp -pdv ${pkgs.glibc}/lib/libnss_dns*.so* $out/lib
    '';

    initramfs.profile = ''
      start_iperf_client() {
        while true; do
          [ -f /stop ] || \
            chrt -b 0 iperf3 -c ${hostAddr} && cat /proc/interrupts && sleep 10 && \
            chrt -b 0 iperf3 -R -c ${hostAddr} && cat /proc/interrupts && sleep 10 || \
            break;
        done
        # chrt -b 0 iperf3 -c ${hostAddr}
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

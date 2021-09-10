{ pkgs, lib, ... }:

let
  virtualIface = "eth0";
  hostAddr = "192.168.1.1";
  realmAddr = "192.168.1.2";
in

{
  config = {

    net.interfaces.eth0.static = "${realmAddr}/24";

    initramfs.extraInitCommands = ''
      echo "nameserver 1.1.1.1" > /etc/resolv.conf
      ip route add default via ${hostAddr} dev ${virtualIface}

      for _ in $(seq 3); do
        sysbench --test=cpu --cpu-max-prime=20000 --num-threads=1 run
        sleep 5
      done

      while true; do iperf3 -c ${hostAddr} && sleep 5 || break; done

      # chrt -b 0 iperf3 -c ${hostAddr}
    '';

    initramfs.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
      copy_bin_and_libs ${pkgs.sysbench}/bin/sysbench
      copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
      cp -pdv ${pkgs.glibc}/lib/libnss_dns*.so* $out/lib
    '';

    initramfs.profile = ''
      i() {
        iperf3 -c ${hostAddr}
      }
      c() {
        curl http://example.com
      }
    '';

  };
}

{ pkgs, lib, ... }:

let
  virtualIface = "eth0";
  hostAddr = "192.168.1.1";
  realmAddr = "192.168.1.2";
  devAddr = "10.0.2.2"; # $(nix-build -A pkgs.dev.iperf3)/bin/iperf3 -s
  devNCPort = "9001";
in

{
  config = {

    net.interfaces.eth0.static = "${realmAddr}/24";

    initramfs.extraInitCommands = ''
      echo 2 > /proc/sys/kernel/randomize_va_space
      ulimit -c unlimited

      sysctl -w net.core.netdev_budget=600
      sysctl -w net.core.netdev_budget_usecs=20000

      echo "nameserver 1.1.1.1" > /etc/resolv.conf
      ip route add default via ${hostAddr} dev ${virtualIface}

      (while true; do [ -f /stop ] || chrt -b 0 iperf3 -c ${hostAddr} || break; done) &
    '';

    initramfs.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.ethtool}/bin/ethtool
      copy_bin_and_libs ${pkgs.netcat}/bin/nc
      copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
      copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
      cp -pdv ${pkgs.glibc}/lib/libnss_dns*.so* $out/lib
    '';
      # cp -pdv ${pkgs.libunwind}/lib/libunwind-aarch64*.so* $out/lib

    initramfs.profile = ''
      ig() {
        while true; do [ -f /stop ] || chrt -b 0 iperf3 -c $1 || break; done
      }
      ih() {
        ig ${hostAddr}
      }
      id() {
        ig ${devAddr}
      }
      ik() {
        touch /stop
        pkill iperf3
      }
      c() {
        curl google.com
      }
      l() {
        nc -l ${realmAddr} 8080
      }
    '';

  };
}
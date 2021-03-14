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
    '';

    initramfs.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.netcat}/bin/nc
      copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
      copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
      cp -pdv ${pkgs.glibc}/lib/libnss_dns*.so* $out/lib
    '';
      # cp -pdv ${pkgs.libunwind}/lib/libunwind-aarch64*.so* $out/lib

    initramfs.profile = ''
      i() {
        iperf3 -c ${hostAddr}
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

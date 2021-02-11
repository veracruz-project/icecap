{ pkgs, lib, ... }:

let
  vif = "eth0";
in

{
  config = {

    initramfs.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
      copy_bin_and_libs ${pkgs.mkinitcpio-nfs-utils}/bin/ipconfig
      copy_bin_and_libs ${pkgs.iproute}/bin/ip
      copy_bin_and_libs ${pkgs.strace}/bin/strace
      copy_bin_and_libs ${pkgs.netcat}/bin/nc
      copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
      cp -pdv ${pkgs.libunwind}/lib/libunwind-aarch64*.so* $out/lib
      cp -pdv ${pkgs.glibc}/lib/libnss_dns*.so* $out/lib
    '';

    net.interfaces.eth0.static = "192.168.1.4/24";

    initramfs.profile = ''
      p() {
        mkdir -p mnt
        mount -t 9p -o trans=tcp,version=9p2000.L,cache=loose,port=1337 192.168.1.1 mnt
      }
      i() {
        iperf3 -c 192.168.1.1
      }
      t() {
        time sha256sum "$@"
      }
      x() {
        nc -l 1337
      }
      r() {
        ip route add default via 192.168.1.1 dev ${vif}
      }
    '';

  };
}

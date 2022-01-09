{ pkgs, lib, ... }:

let
  virtualIface = "eth0";
  hostAddr = "192.168.1.1";
  realmAddr = "192.168.1.2";
in

{
  config = {

    net.interfaces.eth0.static = "${realmAddr}/24";

    initramfs.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
      copy_bin_and_libs ${pkgs.sysbench}/bin/sysbench
      copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
      cp -pdv ${pkgs.glibc}/lib/libnss_dns*.so* $out/lib
    '';

    initramfs.extraInitCommands = ''
      # HACK
      seq 0xfffffff | gzip | head -c $(cat /proc/sys/kernel/random/poolsize) > /dev/urandom

      echo "nameserver 1.1.1.1" > /etc/resolv.conf
      ip route add default via ${hostAddr} dev ${virtualIface}

      # iperf3 -s -1
      # iperf3 -c ${hostAddr} --bidir
    '';

    # -c --bidir
    # -c -R

    initramfs.profile = ''
      x() {
        sysbench cpu --cpu-max-prime=20000 --num-threads=1 run
      }

      # i() {
      #   iperf3 -c ${hostAddr}
      # }
      # c() {
      #   curl http://example.com
      # }
    '';

  };
}

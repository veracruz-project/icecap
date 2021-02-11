{ icecapPlat }:

{ config, pkgs, lib, ... }:

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

    initramfs.extraInitCommands = lib.optionalString (icecapPlat == "rpi4") ''
      (
        echo TODO cpufreq
        # cd /sys/devices/system/cpu/cpu0/cpufreq/
        # echo userspace > scaling_governor
        # echo 1500000 > scaling_setspeed
      )
    '';

    net.interfaces.${vif}.static = "192.168.1.1/24";

    initramfs.profile = ''
      i() {
        iperf3 -s
      }
    '';

  };
}

{ lib, config, pkgs, ... }:

let
  cfg = config.instance;

  devAddr = "10.0.2.2"; # $(nix-build -A pkgs.dev.iperf3)/bin/iperf3 -s
  devNCPort = "9001";

in {
  config = {

    initramfs.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.netcat}/bin/nc
      copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
    '';

    initramfs.extraInitCommands = ''
      echo 2 > /proc/sys/kernel/randomize_va_space
      ulimit -c unlimited
    '';

    initramfs.profile = ''
      i() {
        while true; do [ -f /stop ] || chrt -b 0 iperf3 -c $1 || break; done
      }
      id() {
        ig ${devAddr}
      }
      ik() {
        touch /stop
        pkill iperf3
      }
      c() {
        curl http://example.com
      }
    '';

  };
}

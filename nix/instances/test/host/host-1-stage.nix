{ config, pkgs, lib, ... }:

let
  # vif = "eth0";
  # qif = "eth1";
  qif = "eth0";
  udhcpc_sh = pkgs.writeScript "udhcpc.sh" ''
    #!${config.build.extraUtils}/bin/sh
    if [ "$1" = bound ]; then
      ip address add "$ip/$mask" dev "$interface"
      if [ -n "$mtu" ]; then
        ip link set mtu "$mtu" dev "$interface"
      fi
      if [ -n "$staticroutes" ]; then
        echo "$staticroutes" \
          | sed -r "s@(\S+) (\S+)@ ip route add \"\1\" via \"\2\" dev \"$interface\" ; @g" \
          | sed -r "s@ via \"0\.0\.0\.0\"@@g" \
          | /bin/sh
      fi
      if [ -n "$router" ]; then
        ip route add "$router" dev "$interface" # just in case if "$router" is not within "$ip/$mask" (e.g. Hetzner Cloud)
        ip route add default via "$router" dev "$interface"
      fi
      if [ -n "$dns" ]; then
        rm -f /etc/resolv.conf
        for i in $dns; do
          echo "nameserver $dns" >> /etc/resolv.conf
        done
      fi
    fi
  '';

in {
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

    initramfs.extraInitCommands = ''
      (
        cd /sys/devices/system/cpu/cpu0/cpufreq/
        echo userspace > scaling_governor
        echo 1500000 > scaling_setspeed
      )

      echo "setting up ${qif}..."
      ip link set ${qif} up
      echo -n 'sleeping... '
      sleep 5
      echo done

      mkdir -p /etc /bin
      ln -s $(which sh) /bin/sh
      udhcpc --quit --now -i ${qif} -O staticroutes --script ${udhcpc_sh}
    '';

    # initramfs.profile = ''
    # '';

  };
}

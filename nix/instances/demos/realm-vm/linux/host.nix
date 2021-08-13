{ icecapPlat, spec }:

{ config, pkgs, lib, ... }:

let
  virtualIface = "eth0";
  physicalIface = "eth10";
  hostAddr = "192.168.1.1";
  realmAddr = "192.168.1.2";
  devAddr = "10.0.2.2";

  udhcpcScript = pkgs.writeScript "udhcpc.sh" ''
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
  nftScript = pkgs.writeText "nftables" ''
    table ip nat {
      chain prerouting {
        type nat hook prerouting priority 0;
      }
      chain postrouting {
        type nat hook postrouting priority 100;
        oifname "${physicalIface}" masquerade
      }
    }
  '';

in

{
  config = {

    net.interfaces.${virtualIface}.static = "${hostAddr}/24";
    net.interfaces.lo = { static = "127.0.0.1"; };

    initramfs.extraInitCommands = ''
      echo 2 > /proc/sys/kernel/randomize_va_space
      ulimit -c unlimited

      mkdir -p /etc /bin /mnt/nix/store
      ln -s $(which sh) /bin/sh

      sysctl -w net.ipv4.ip_forward=1

      mount -t debugfs none /sys/kernel/debug/

    '' + lib.optionalString (icecapPlat == "virt") ''
      ip link set ${physicalIface} up
      udhcpc --quit --now -i ${physicalIface} -O staticroutes --script ${udhcpcScript}
      nft -f ${nftScript}
      physicalAddr=$(ip address show dev ${physicalIface} | sed -nr 's,.*inet ([^/]*)/.*,\1,p')
      nft add rule ip nat prerouting ip daddr "$physicalAddr" tcp dport 8080 dnat to ${realmAddr}:8080

      mount -t 9p -o trans=virtio,version=9p2000.L,ro store /mnt/nix/store/
      spec="$(sed -rn 's,.*spec=([^ ]*).*,\1,p' /proc/cmdline)"
      echo "cp -L /mnt/$spec /spec.bin..."
      # cp -L "/mnt/$spec" /spec.bin
      ln -s "/mnt/$spec" /spec.bin
      echo "...done"

    '' + lib.optionalString (icecapPlat == "rpi4") ''
      (
        cd /sys/devices/system/cpu/cpu0/cpufreq/
        echo userspace > scaling_governor
        echo 1500000 > scaling_setspeed
      )

      mount -o ro /dev/mmcblk0p1 mnt/
      ln -s /mnt/spec.bin /spec.bin
    '' + ''
      affinity=0x4
      # taskset $affinity /bin/sh -c "while true; do true; done" &
      # taskset $affinity /bin/sh -c "while true; do sleep 1; echo awake; done" &
      icecap-host create 0 /spec.bin && taskset $affinity icecap-host run 0 0 &
    '';

    initramfs.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.icecap.icecap-host}/bin/icecap-host
      copy_bin_and_libs ${pkgs.strace}/bin/strace
      copy_bin_and_libs ${pkgs.iproute}/bin/ip
      copy_bin_and_libs ${pkgs.nftables}/bin/nft
      copy_bin_and_libs ${pkgs.netcat}/bin/nc
      copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
      copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
      cp -pdv ${pkgs.libunwind}/lib/libunwind-aarch64*.so* $out/lib
      cp -pdv ${pkgs.glibc}/lib/libnss_dns*.so* $out/lib
    '';

    initramfs.profile = ''
      ic() {
        icecap-host create 0 /spec.bin && icecap-host run 0 0
      }
      id() {
        icecap-host destroy 0
      }
      i() {
        iperf3 -s
      }
      c() {
        curl google.com
      }
      s() {
        while true; do sha256sum /mnt/${pkgs.pkgs_none.icecap.linuxKernel.host.virt}/vmlinux-5.6.0-rc2; done
      }
    '';

  };
}

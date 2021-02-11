{ pkgs, lib, config, ... }:

with lib;

let
  vif = "eth0";
  qif = "eth1";
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
  extraPackages = with pkgs; [
    iproute
    iperf
    icecap._9p-server
    iptables
    nftables
    ethtool
  ];
  nft_script = pkgs.writeText "nftables" ''
    table ip nat {
      chain prerouting {
        type nat hook prerouting priority 0; policy accept;
        # iifname wan0 tcp dport 80 dnat 192.168.0.8 comment "Port forwarding to web server"
      }
      chain postrouting {
        type nat hook postrouting priority 100; policy accept;
        oifname "${qif}" masquerade
      }
    }
  '';

in {
  options =  {
    icecap.plat = mkOption {
      default = null;
      type = types.unspecified;
    };
    rpi4._9p = {
      port = mkOption {
        default = null;
        type = types.unspecified;
      };
      addr = mkOption {
        default = null;
        type = types.unspecified;
      };
    };
  };
  config = {
    initramfs.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
      copy_bin_and_libs ${pkgs.mkinitcpio-nfs-utils}/bin/ipconfig
      copy_bin_and_libs ${pkgs.iproute}/bin/ip
      copy_bin_and_libs ${pkgs.strace}/bin/strace
      copy_bin_and_libs ${pkgs.netcat}/bin/nc
      copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
      copy_bin_and_libs ${pkgs.cpufrequtils}/bin/cpufreq-info
      copy_bin_and_libs ${pkgs.cpufrequtils}/bin/cpufreq-set
      cp -pdv ${pkgs.libunwind}/lib/libunwind-aarch64*.so* $out/lib
      cp -pdv ${pkgs.glibc}/lib/libnss_dns*.so* $out/lib
    '';
    initramfs.mntCommands = ''
      echo "setting up ${qif}..."
      ip link set ${qif} up
      # echo -n 'sleeping... '
      # sleep 5
      # echo done

      mkdir -p /etc /bin
      ln -s $(which sh) /bin/sh
      udhcpc --quit --now -i ${qif} -O staticroutes --script ${udhcpc_sh}

      ${{
        virt = ''
          mount -t 9p -o trans=virtio,version=9p2000.L,ro store $nix_store_mnt
        '';
        rpi4 = ''
          echo -n 'mounting nix store... '
          mount -t 9p -o trans=tcp,version=9p2000.L,cache=loose,port=${toString config.rpi4._9p.port} ${config.rpi4._9p.addr} $nix_store_mnt
          echo done
        '';
      }.${config.icecap.plat}}

      mkdir -p $target_root/etc
      cp /etc/resolv.conf $target_root/etc
    '';
    env.extraPackages = extraPackages;

    initramfs.extraNextInit = ''
      echo "setting up ${vif}..."
      ip link set ${vif} up
      ip address add 192.168.1.1/24 dev ${vif}
    '';

    initramfs.profile = ''
      p() {
        icecap-p9-server-linux-cli 192.168.1.1:1337
      }
      i() {
        iperf3 -s
      }
      x() {
        echo foo | nc 192.168.1.4 1337
      }
      ix() {
        nc 192.168.1.4 1337
      }
      nf() {
        nft -f ${nft_script}
      }

      sct() {
        sysctl -w net.ipv4.ip_forward=1
        # sysctl -w net.ipv4.conf.all.forwarding=1
        # sysctl -w net.ipv4.conf.default.forwarding=1
      }
    '';
  };
}

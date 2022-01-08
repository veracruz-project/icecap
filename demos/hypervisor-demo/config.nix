{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.instance;

  hostAddr = "192.168.1.1";
  realmAddr = "192.168.1.2";

  virtualIface = {
    virt = "eth0";
    rpi4 = "eth0";
  }.${cfg.plat};

  physicalIface = {
    virt = "eth2";
    rpi4 = "eth2";
  }.${cfg.plat};

  nftScript = pkgs.writeText "nat.nft" ''
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
  options.instance = {
    plat = mkOption {
      type = types.unspecified;
    };
  };

  config = lib.mkMerge [

    {
      net.interfaces.${virtualIface}.static = "${hostAddr}/24";
      net.interfaces.lo.static = "127.0.0.1";
    }

    (mkIf (cfg.plat == "virt") {
      net.interfaces.${physicalIface} = {};
    })

    {
      initramfs.extraInitCommands = ''
        mkdir -p /etc /bin
        ln -s $(which sh) /bin/sh

        mount -t debugfs none /sys/kernel/debug/
      '';
    }

    (mkIf (cfg.plat == "virt") {
      initramfs.extraInitCommands = ''
        sysctl -w net.ipv4.ip_forward=1
        nft -f ${nftScript}
        physicalAddr=$(ip address show dev ${physicalIface} | sed -nr 's,.*inet ([^/]*)/.*,\1,p')
        nft add rule ip nat prerouting ip daddr "$physicalAddr" tcp dport 8080 dnat to ${realmAddr}:8080

        mkdir -p /mnt/nix/store
        mount -t 9p -o trans=virtio,version=9p2000.L,ro store /mnt/nix/store/

        copy_spec() {
          name=$1-realm-spec
          spec="$(sed -rn 's,.*'"$name"'=([^ ]*).*,\1,p' /proc/cmdline)"
          (set -x && cp -L "/mnt/$spec" /$name.bin)
        }

        copy_spec vm
        copy_spec mirage
      '';
    })

    (mkIf (cfg.plat == "rpi4") {
      initramfs.extraInitCommands = ''
        sleep 2 # HACK
        mount -o ro /dev/mmcblk0p1 mnt/
        ln -s /mnt/*-realm-spec.bin /
      '';
    })

    {
      initramfs.extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.icecap.icecap-host}/bin/icecap-host
        copy_bin_and_libs ${pkgs.iproute}/bin/ip
        copy_bin_and_libs ${pkgs.nftables}/bin/nft
        copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
        copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
        cp -pdv ${pkgs.glibc}/lib/libnss_dns*.so* $out/lib
      '';

      initramfs.profile = ''
        create() {
          name=$1-realm-spec
          icecap-host create 0 /$1-realm-spec.bin && taskset 0x2 icecap-host run 0 0
        }

        destroy() {
          icecap-host destroy 0
        }

        test_mirage_echo() {
          echo "$@" | nc 192.168.1.2 8080
        }

        alias c=create
        alias d=destroy
        alias m=test_mirage_echo
      '';
    }

  ];

}

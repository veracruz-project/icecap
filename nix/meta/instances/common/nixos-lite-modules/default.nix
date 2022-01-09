{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.instance;

in {

  options.instance = {

    host.enable = mkOption {
      type = lib.types.bool;
      default = false;
    };

    host.plat = mkOption {
      type = lib.types.unspecified;
    };

    realm.enable = mkOption {
      type = lib.types.bool;
      default = false;
    };

    # HACK
    misc = mkOption {
      default = {};
      type = lib.types.attrs;
    };
  };

  config = mkMerge [

    {
      instance.misc.net.hostAddr = "192.168.1.1";
      instance.misc.net.realmAddr = "192.168.1.2";

      initramfs.extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.iproute}/bin/ip
        cp -pdv ${pkgs.glibc}/lib/libnss_dns*.so* $out/lib
        cp -pdv ${pkgs.libunwind}/lib/libunwind-aarch64*.so* $out/lib
      '';

      initramfs.extraInitCommands = ''
        # HACK
        seq 0xfffffff | gzip | head -c $(cat /proc/sys/kernel/random/poolsize) > /dev/urandom

        mkdir -p /bin
        ln -s $(which sh) /bin/sh
      '';
    }

    (mkIf cfg.host.enable (mkMerge [
      {
        net.interfaces.${cfg.misc.host.virtualIface}.static = "${cfg.misc.net.hostAddr}/24";
        net.interfaces.lo.static = "127.0.0.1";

        instance.misc.host.virtualIface = {
          virt = "eth0";
          rpi4 = "eth0";
        }.${cfg.host.plat};

        instance.misc.host.physicalIface = {
          virt = "eth2";
          rpi4 = "eth2";
        }.${cfg.host.plat};

        instance.misc.host.nftablesScriptForNat = pkgs.writeText "nat.nft" ''
          table ip nat {
            chain prerouting {
              type nat hook prerouting priority 0;
            }
            chain postrouting {
              type nat hook postrouting priority 100;
              oifname "${cfg.misc.host.physicalIface}" masquerade
            }
          }
        '';

        initramfs.extraUtilsCommands = ''
          copy_bin_and_libs ${pkgs.icecap.icecap-host}/bin/icecap-host
          copy_bin_and_libs ${pkgs.nftables}/bin/nft
        '';

        initramfs.extraInitCommands = ''
          mount -t debugfs none /sys/kernel/debug/
        '';
      }

      (mkIf (cfg.host.plat == "virt") {
        net.interfaces.${cfg.misc.host.physicalIface} = {};

        initramfs.extraInitCommands = ''
          sysctl -w net.ipv4.ip_forward=1
          nft -f ${cfg.misc.host.nftablesScriptForNat}
          physicalAddr=$(ip address show dev ${cfg.misc.host.physicalIface} | sed -nr 's,.*inet ([^/]*)/.*,\1,p')
          nft add rule ip nat prerouting ip daddr "$physicalAddr" tcp dport 8080 dnat to ${cfg.misc.net.realmAddr}:8080

          mkdir -p  /mnt/nix/store
          mount -t 9p -o trans=virtio,version=9p2000.L,ro store /mnt/nix/store
          spec="$(sed -rn 's,.*spec=([^ ]*).*,\1,p' /proc/cmdline)"
          echo "cp -L /mnt/$spec /spec.bin..."
          cp -L "/mnt/$spec" /spec.bin
          echo "...done"
        '';
      })

      (mkIf (cfg.host.plat == "rpi4") {
        initramfs.extraInitCommands = ''
          for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            (set -x && echo performance > $f)
          done

          sleep 2 # HACK
          mkdir -p /mnt
          mount -o ro /dev/mmcblk0p1 /mnt
          ln -s /mnt/spec.bin /spec.bin
      '';
      })
    ]))

    (mkIf cfg.realm.enable {
      instance.misc.realm.virtualIface = "eth0";

      net.interfaces.${cfg.misc.realm.virtualIface}.static = "${cfg.misc.net.realmAddr}/24";

      initramfs.extraInitCommands = ''
        echo "nameserver 1.1.1.1" > /etc/resolv.conf
        ip route add default via ${cfg.misc.net.hostAddr} dev ${cfg.misc.realm.virtualIface}
      '';
    })

  ];

}

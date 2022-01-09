{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.instance;

  virtualIface = "eth0";
  physicalIface = "eth2";
  hostAddr = "192.168.1.1";
  realmAddr = "192.168.1.2";
  devAddr = "10.0.2.2";
  localIperfPort = "8001";

  nftScript = config.lib.instance.mkNftablesScriptForNat { inherit physicalIface; };

in

{
  config = lib.mkMerge [

    {
      net.interfaces.${virtualIface}.static = "${hostAddr}/24";
      net.interfaces.lo = { static = "127.0.0.1"; };
    }

    (mkIf (cfg.plat == "virt") {
      net.interfaces.${physicalIface} = {};
    })

    {
      initramfs.extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.icecap.muslPkgs.icecap.icecap-host}/bin/icecap-host
        copy_bin_and_libs ${pkgs.ethtool}/bin/ethtool
        copy_bin_and_libs ${pkgs.strace}/bin/strace
        copy_bin_and_libs ${pkgs.iproute}/bin/ip
        copy_bin_and_libs ${pkgs.nftables}/bin/nft
        copy_bin_and_libs ${pkgs.netcat}/bin/nc
        copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
        copy_bin_and_libs ${pkgs.sysbench}/bin/sysbench
        copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
        cp -pdv ${pkgs.libunwind}/lib/libunwind-aarch64*.so* $out/lib
        cp -pdv ${pkgs.glibc}/lib/libnss_dns*.so* $out/lib
      '';

      initramfs.extraInitCommands = ''
        echo 2 > /proc/sys/kernel/randomize_va_space
        ulimit -c unlimited

        mkdir -p /etc /bin /mnt/nix/store
        ln -s $(which sh) /bin/sh

        sysctl -w net.ipv4.ip_forward=1

        # sysctl -w net.core.busy_poll=50
        # sysctl -w net.core.busy_read=50

        # sysctl -w net.core.netdev_budget=300 # default
        # sysctl -w net.core.netdev_budget=600
        # sysctl -w net.core.netdev_budget=1200

        # sysctl -w net.core.netdev_budget_usecs=2000 # default
        # sysctl -w net.core.netdev_budget_usecs=20000

        mount -t debugfs none /sys/kernel/debug/
      '';
    }

    (mkIf (cfg.plat == "virt") {
      initramfs.extraInitCommands = ''
        nft -f ${nftScript}
        physicalAddr=$(ip address show dev ${physicalIface} | sed -nr 's,.*inet ([^/]*)/.*,\1,p')
        nft add rule ip nat prerouting ip daddr "$physicalAddr" tcp dport 8080 dnat to ${realmAddr}:8080

        mount -t 9p -o trans=virtio,version=9p2000.L,ro store /mnt/nix/store/
        spec="$(sed -rn 's,.*spec=([^ ]*).*,\1,p' /proc/cmdline)"
        echo "cp -L /mnt/$spec /spec.bin..."
        # cp -L "/mnt/$spec" /spec.bin
        ln -s "/mnt/$spec" /spec.bin
        echo "...done"
      '';
    })

    (mkIf (cfg.plat == "rpi4") {
      initramfs.extraInitCommands = ''
        for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
          echo $f
          echo performance > $f
        done

        sleep 2 # HACK
        mount -o ro /dev/mmcblk0p1 mnt/
        ln -s /mnt/spec.bin /spec.bin
      '';
    })

    {
      initramfs.extraInitCommands = ''
        # https://access.redhat.com/solutions/177953
        # https://www.redhat.com/files/summit/session-assets/2018/Performance-analysis-and-tuning-of-Red-Hat-Enterprise-Linux-Part-1.pdf
        # echo 10000000 > /proc/sys/kernel/sched_min_granularity_ns
        # echo 15000000 > /proc/sys/kernel/sched_wakeup_granularity_ns

        # for _ in $(seq 2); do
        #   sysbench cpu --cpu-max-prime=20000 --num-threads=1 run
        #   sleep 5
        # done

        export iperf_affinity=0x4
        chrt -b 0 iperf3 -s > /dev/null &
        # taskset $iperf_affinity chrt -b 0 iperf3 -s > /dev/null &
        # taskset $iperf_affinity chrt -b 0 iperf3 -s -p ${localIperfPort} > /dev/null &

        export realm_affinity=0x2
        taskset $realm_affinity icecap-host create 0 /spec.bin && \
          chrt -b 0 taskset $realm_affinity icecap-host run 0 0 &
      '';

      initramfs.profile = ''
        ic() {
          taskset $realm_affinity icecap-host create 0 /spec.bin && \
            chrt -b 0 taskset $realm_affinity icecap-host run 0 0 &
        }
        id() {
          icecap-host destroy 0
        }
        i() {
          taskset $iperf_affinity chrt -b 0 iperf3 -s > /dev/null &
        }
        ik() {
          pkill iperf3
        }
        c() {
          curl google.com
        }
        s() {
          while true; do sha256sum /mnt/${pkgs.icecap.linuxPkgs.icecap.linuxKernel.host.virt}/vmlinux-5.6.0-rc2; done
        }
      '';
    }
  ];
}

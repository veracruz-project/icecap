{ config, pkgs, lib, ... }:

with lib;

with import ./common.nix;

let

  cfg = config.instance;

  physicalIface = {
    virt = "eth0";
    rpi4 = "eth0";
  }.${cfg.plat};

  # firecrackerPkg = pkgs.icecap.firecracker-prebuilt;
  firecrackerPkg = pkgs.icecap.muslPkgs.icecap.firecracker;
  # firecrackerPkg = pkgs.icecap.firecracker;
  # firecrackerPkg = localFirecracker;

  localFirecrackerPath = ../../../../../local/firecracker/target/aarch64-unknown-linux-musl/debug/firecracker;
  # localFirecrackerPath = ../../../../../local/firecracker/target/aarch64-unknown-linux-gnu/debug/firecracker;

  localFirecracker = pkgs.runCommand "firecracker-local" {} ''
    install -D -T ${localFirecrackerPath} $out/bin/firecracker
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
      net.interfaces.lo.static = "127.0.0.1";

      initramfs.extraInitCommands = ''
        mkdir -p /bin
        ln -s $(which sh) /bin/sh
      '';

      initramfs.extraUtilsCommands = ''
        copy_bin_and_libs ${firecrackerPkg}/bin/firecracker
        copy_bin_and_libs ${pkgs.icecap.firectl}/bin/firectl
        copy_bin_and_libs ${pkgs.iproute}/bin/ip
        copy_bin_and_libs ${pkgs.nftables}/bin/nft
        copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
        copy_bin_and_libs ${pkgs.sysbench}/bin/sysbench
        copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
        cp -pdv ${pkgs.glibc}/lib/libnss_dns*.so* $out/lib
      '';
    }

    (mkIf (cfg.plat == "virt") {
      net.interfaces.${physicalIface} = {};

      initramfs.extraInitCommands = ''
        mkdir -p /mnt/nix/store
        mount -t 9p -o trans=virtio,version=9p2000.L,ro store /mnt/nix/store

        script="$(sed -rn 's,.*script=([^ ]*).*,\1,p' /proc/cmdline)"
        ln -s /mnt/$script /script
      '';
    })

    (mkIf (cfg.plat == "rpi4") {
      initramfs.extraInitCommands = ''
        for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
          echo $f
          echo performance > $f
        done

        echo "waiting 2 seconds for mmc..."
        sleep 2

        mkdir -p /mnt
        mount -o ro /dev/mmcblk0p1 /mnt
        ln -s /mnt/$script /script
      '';
    })

    {
      initramfs.extraInitCommands = ''
        . /etc/profile

        ip tuntap add veth0 mode tap
        ip address add ${hostAddr}/24 dev veth0
        ip link set veth0 up

        # for _ in $(seq 2); do
        #   host__cpu
        #   sleep 10
        # done

        export iperf_affinity=0x1
        # taskset $iperf_affinity \
          iperf3 -s > /dev/null &

        export realm_affinity=0x2
        # taskset $realm_affinity \
          /script
      '';

      initramfs.profile = ''
        host_cpu() {
          sysbench cpu --cpu-max-prime=20000 --num-threads=1 run
        }
      '';
    }
  ];
}
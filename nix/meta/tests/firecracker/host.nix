{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.instance;

  physicalIface = {
    virt = "eth0";
    rpi4 = "eth0";
  }.${cfg.plat};

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
        sysctl -w net.ipv4.ip_forward=1

        mkdir -p /etc /bin /mnt/nix/store
        ln -s $(which sh) /bin/sh
      '';

        # copy_bin_and_libs ${pkgs.muslPkgs.icecap.firecracker}/bin/firecracker
      initramfs.extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.icecap.firecracker-prebuilt}/bin/firecracker
        copy_bin_and_libs ${pkgs.icecap.firectl}/bin/firectl
        copy_bin_and_libs ${pkgs.iproute}/bin/ip
        copy_bin_and_libs ${pkgs.nftables}/bin/nft
        copy_bin_and_libs ${pkgs.iperf3}/bin/iperf3
        copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
        cp -pdv ${pkgs.glibc}/lib/libnss_dns*.so* $out/lib
      '';
    }

    (mkIf (cfg.plat == "virt") {
      net.interfaces.${physicalIface} = {};

      initramfs.extraInitCommands = ''
        mount -t 9p -o trans=virtio,version=9p2000.L,ro store /mnt/nix/store/

        script="$(sed -rn 's,.*script=([^ ]*).*,\1,p' /proc/cmdline)"
        ln -s /mnt/$script /script
      '';
    })

    (mkIf (cfg.plat == "rpi4") {
      initramfs.extraInitCommands = ''
        echo "waiting 2 seconds for mmc..."
        sleep 2

        mount -o ro /dev/mmcblk0p1 mnt/
        ln -s /mnt/$script /script

        for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
          echo $f
          echo performance > $f
        done
      '';
    })

    {
      initramfs.extraInitCommands = ''
        ip tuntap add veth0 mode tap
        ip address add 192.168.1.1/24 dev veth0
        ip link set veth0 up

        export iperf_affinity=0x1
        # taskset $iperf_affinity \
          iperf3 -s > /dev/null &

        export realm_affinity=0x2
        # taskset $realm_affinity \
          /script
      '';
    }

  ];
}
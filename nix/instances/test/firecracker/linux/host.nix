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

        # copy_bin_and_libs ${pkgs.pkgs_musl.icecap.firecracker}/bin/firecracker
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
        echo "waiting 5 seconds for mmc..."
        sleep 5

        mount -o ro /dev/mmcblk0p1 mnt/
        ln -s /mnt/$script /script

        (
          cd /sys/devices/system/cpu/cpu0/cpufreq/
          echo performance > scaling_governor
          # echo userspace > scaling_governor
          # echo 1500000 > scaling_setspeed
        )
      '';
    })

    {
      initramfs.extraInitCommands = ''
        iperf3 -s &
        /script
      '';
    }

  ];
}

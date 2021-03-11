{ lib, writeText, writeScript, runCommand
, raspbian
, uboot-ng, uboot-ng-mkimage
, mkIceCapSrc
}:

let

  uBootSource = uboot-ng.doSource {
    version = "2019.07";
    src = (mkIceCapSrc {
      repo = "u-boot";
      rev = "62b6e39a53c56a9085aeab1b47b5cc6020fcdb6f"; # branch icecap
    }).store;
  };

  preConfig = uboot-ng.makeConfig {
    source = uBootSource;
    target = "rpi_4_defconfig";
  };

  config = runCommand "config" {} ''
    substitute ${preConfig} $out \
      --replace BOOTDELAY=2 BOOTDELAY=0 \
      --replace 'BOOTCOMMAND="run distro_bootcmd"' 'BOOTCOMMAND="${bootcmd}"'
  '';

  scriptPartition = "mmc 0:1";
  scriptAddr = "0x100000";
  scriptName = "load-icecap.script.uimg";
  icecapAddr = "0x30000000";
  scriptUimg = uboot-ng-mkimage {
    type = "script";
    data = writeText "script.txt" ''
      load mmc 0:1 ${icecapAddr} /icecap.elf
      bootelf ${icecapAddr}
    '';
  };

  bootcmd = "load ${scriptPartition} ${scriptAddr} ${scriptName}; source ${scriptAddr}";

  uBoot = uboot-ng.doKernel rec {
    source = uBootSource;
    inherit config;
  };

  uBootBin = "${uBoot}/u-boot.bin";

  configTxt = writeText "config.txt" ''
    enable_uart=1
    arm_64bit=1
    enable_jtag_gpio=1
  '';

  bootPartitionLinks = { image, payload ? {}, extraBootPartitionCommands ? "" }:
    runCommand "boot" {} ''
      mkdir $out
      ln -s ${raspbian.latest.boot}/*.* $out
      mkdir $out/overlays
      ln -s ${raspbian.latest.boot}/overlays/*.* $out/overlays

      ln -sf ${configTxt} $out/config.txt

      rm $out/kernel*.img
      ln -s ${uBootBin} $out/kernel8.img
      ln -s ${scriptUimg} $out/${scriptName}

      ln -s ${image} $out/icecap.elf
      mkdir $out/payload
      ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
        ln -s ${v} $out/payload/${k}
      '') payload)}

      ${extraBootPartitionCommands}
    '';

in {
  inherit uBoot bootPartitionLinks;
}

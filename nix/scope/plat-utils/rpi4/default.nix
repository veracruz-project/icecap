{ lib, writeText, writeScript, runCommand
, raspios
, icecapSrc
, linuxPkgs
}:

let

  uBootSource = linuxPkgs.uboot-ng.doSource {
    version = "2019.07";
    src = (icecapSrc.repo {
      repo = "u-boot";
      rev = "62b6e39a53c56a9085aeab1b47b5cc6020fcdb6f"; # branch icecap
    }).store;
  };

  preConfig = linuxPkgs.uboot-ng.makeConfig {
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
  defaultScript = writeText "script.txt" ''
    load mmc 0:1 ${icecapAddr} /icecap.elf
    bootelf ${icecapAddr}
  '';

  bootcmd = "load ${scriptPartition} ${scriptAddr} ${scriptName}; source ${scriptAddr}";

  uBoot = linuxPkgs.uboot-ng.doKernel rec {
    source = uBootSource;
    inherit config;
  };

  uBootBin = "${uBoot}/u-boot.bin";

  configTxt = writeText "config.txt" ''
    enable_uart=1
    arm_64bit=1
    enable_jtag_gpio=1
  '';

  bootPartitionLinks = { image ? null, payload ? {}, extraBootPartitionCommands ? "", script ? defaultScript }:
    let
      scriptUimg = linuxPkgs.uboot-ng-mkimage {
        type = "script";
        data = script;
      };
    in
    runCommand "boot" {} ''
      mkdir $out
      ln -s ${raspios.latest.boot}/*.* $out
      mkdir $out/overlays
      ln -s ${raspios.latest.boot}/overlays/*.* $out/overlays

      ln -sf ${configTxt} $out/config.txt

      rm $out/cmdline.txt
      rm $out/kernel*.img
      ln -s ${uBootBin} $out/kernel8.img
      ln -s ${scriptUimg} $out/${scriptName}

      ${lib.optionalString (image != null) ''
        ln -s ${image} $out/icecap.elf
      ''}
      mkdir $out/payload
      ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
        ln -s ${v} $out/payload/${k}
      '') payload)}

      ${extraBootPartitionCommands}
    '';

  bundle =
    { firmware, payload ? {}
    , extraLinks ? {}
    , platArgs ? {}
    }:

    let
      expandedPlatArgs = (
        { extraBootPartitionCommands ? "" }:
        { inherit extraBootPartitionCommands; }
      ) platArgs;

      boot = bootPartitionLinks {
        image = firmware;
        inherit payload;
        inherit (expandedPlatArgs) extraBootPartitionCommands;
      };

      links = {
        inherit boot;
      } // extraLinks;
    in
    runCommand "run" {
      passthru = {
        inherit boot;
      };
    } ''
      mkdir $out
      ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
        mkdir -p $out/$(dirname ${k})
        ln -s ${v} $out/${k}
      '') links)}
    '';

in {
  inherit bundle;
  extra = {
    inherit uBoot bootPartitionLinks;
  };
}

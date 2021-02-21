{ lib, writeScript, runCommand, buildPackages, elfloader, kernel
, virtUtils
, uboot-ng
, uboot-ng-tools
, uboot-ng-mkimage
, writeText
, raspbian
, runPkgs
, icecapPlat, icecapExtraConfig
, mkIceCapGitUrl
, show-backtrace
}:

let
  kernel_ = kernel;
in

{ payload, extraLinks ? {}, kernel ? kernel_, icecapPlatArgs ? {} }:

with uboot-ng;

with (
  { extraBootPartitionCommands ? "" }:
  { inherit extraBootPartitionCommands; }
) (icecapPlatArgs.${icecapPlat} or {});

let

  source = doSource {
    version = "2019.07";
    # src = lib.cleanSource ../../../../../../local/u-boot;
    src = builtins.fetchGit {
      url = mkIceCapGitUrl "u-boot";
      ref = "icecap";
      rev = "62b6e39a53c56a9085aeab1b47b5cc6020fcdb6f";
    };
  };

  preConfig = makeConfig {
    inherit source;
    target = "rpi_4_defconfig";
  };

  scriptPartition = "mmc 0:1";
  scriptAddr = "0x100000";
  scriptName = "script.uimg";
  buddyAddr = "0x30000000";
  scriptUimg = uboot-ng-mkimage {
    type = "script";
    data = writeText "script.txt" ''
      load mmc 0:1 ${buddyAddr} /buddy.elf
      bootelf ${buddyAddr}
    '';
  };

  bootcmd = "load ${scriptPartition} ${scriptAddr} ${scriptName}; source ${scriptAddr}";

  config = runCommand "config" {} ''
    substitute ${preConfig} $out \
      --replace BOOTDELAY=2 BOOTDELAY=0 \
      --replace 'BOOTCOMMAND="run distro_bootcmd"' 'BOOTCOMMAND="${bootcmd}"'
  '';

  uboot = doKernel rec {
    inherit source config;
  };

  ubootBin = "${uboot}/u-boot.bin";

  configTxt = writeText "config.txt" ''
    enable_uart=1
    arm_64bit=1
    enable_jtag_gpio=1
  '';

  image = elfloader {
    app-elf = payload;
    inherit kernel;
  };

  boot = runCommand "boot" {} ''
    mkdir $out
    mkdir $out/overlays
    ln -s ${raspbian.latest.boot}/*.* $out
    rm $out/kernel*.img
    ln -s ${raspbian.latest.boot}/overlays/*.* $out/overlays
    ln -sf ${configTxt} $out/config.txt
    ln -s ${ubootBin} $out/kernel8.img
    ln -s ${image}/bin/elfloader $out/buddy.elf
    ln -s ${scriptUimg} $out/${scriptName}
    ${extraBootPartitionCommands}
  '';

  syncSimple = src: writeScript "sync" ''
    #!${runPkgs.runtimeShell}
    set -e

    # if [ -z "$1" ]; then
    #   echo "usage: $0 DEV" >&2
    #   exit 1
    # fi

    # dev="$1"

    dev=/dev/disk/by-label/icecap-boot

    mkdir -p mnt
    sudo mount $dev ./mnt
    sudo rm -r ./mnt/* || true
    sudo cp -rvL ${src}/* ./mnt
    sudo umount ./mnt
  '';

  sync = syncSimple boot;

  links = {
    "image.elf" = image.elf;
    "kernel.elf" = image.kernel-elf;
    "kernel.dtb" = image.kernel-dtb;
    "app.elf" = image.app-elf;
    "boot" = boot;
    run = sync;
    "show-backtrace" = "${show-backtrace.nativeDrv}/bin/show-backtrace";
  } // extraLinks;

in
runCommand "run" {
  passthru = {
    inherit image boot uboot;
  };
} ''
  mkdir $out
  ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
    ln -s ${v} $out/${k}
  '') links)}
''

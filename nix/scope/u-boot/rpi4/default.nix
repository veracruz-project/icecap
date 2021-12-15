{ lib, writeText, runCommand
, icecapSrc, icecapExternalSrc
, uboot-ng, uboot-ng-mkimage
}:

with uboot-ng;

let

  source = icecapExternalSrc.u-boot.host.unified;

  preConfig = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = icecapSrc.relative "support/hypervisor/host/rpi4/u-boot.defconfig";
  };

  # config = preConfig;

  config = runCommand "config" {} ''
    substitute ${preConfig} $out \
      --replace 'BOOTCOMMAND="x"' 'BOOTCOMMAND="${bootcmd}"'
  '';

  scriptPartition = "mmc 0:1";
  scriptAddr = "0x10070000";
  scriptName = "load-host.script.uimg";
  scriptPath = "payload/${scriptName}";

  bootcmd = "load ${scriptPartition} ${scriptAddr} ${scriptPath}; source ${scriptAddr}";

  mkDefaultPayload = { linuxImage, initramfs, dtb, bootargs }:
    let
      kernelAddr = "0x10080000";
      initramfsAddr = "0x18000000";
      dtbAddr = "0x12000000";
      script = uboot-ng-mkimage {
        type = "script";
        data = writeText "script.txt" ''
          load mmc 0:1 ${kernelAddr} payload/Image
          load mmc 0:1 ${initramfsAddr} payload/initramfs
          setenv initramfs_size ''${filesize}
          load mmc 0:1 ${dtbAddr} payload/host.dtb
          setenv bootargs ${lib.concatStringsSep " " bootargs}
          booti ${kernelAddr} ${initramfsAddr}:''${initramfs_size} ${dtbAddr}
        '';
      };
    in {
      "${scriptName}" = script;
      Image = linuxImage;
      initramfs = initramfs;
      "host.dtb" = dtb;
    };

in
doKernel rec {
  inherit source config;
  passthru = {
    inherit mkDefaultPayload;
  };
}

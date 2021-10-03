{ lib, writeText, runCommand
, uboot-ng, uboot-ng-mkimage
, uBootUnifiedSource
}:

with uboot-ng;

let

  source = uBootUnifiedSource;

  preConfig = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = ./defconfig;
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
      script = uboot-ng-mkimage {
        type = "script";
        data = writeText "script.txt" ''
          load mmc 0:1 0x10080000 payload/Image
          load mmc 0:1 0x18000000 payload/initramfs
          setenv initramfs_size ''${filesize}
          load mmc 0:1 0x12000000 payload/host.dtb
          setenv bootargs ${lib.concatStringsSep " " bootargs}
          booti 0x10080000 0x18000000:''${initramfs_size} 0x12000000
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

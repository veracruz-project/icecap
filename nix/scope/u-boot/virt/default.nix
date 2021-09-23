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

  scriptAddr = "0xf0000000";
  scriptName = "script.uimg";
  scriptPath = "./result/payload/${scriptName}"; # HACK

  bootcmd = "smhload ${scriptPath} ${scriptAddr}; source ${scriptAddr}";

  mkDefaultPayload = { linuxImage, initramfs, dtb, bootargs }:
    let
      script = uboot-ng-mkimage {
        type = "script";
        data = writeText "script.txt" ''
          smhload ${linuxImage} 0xf0080000
          smhload ${initramfs} 0xf8000000 initramfs_end
          setexpr initramfs_size ''${initramfs_end} - 0xf8000000
          smhload ${dtb} 0xf3000000
          setenv bootargs ${lib.concatStringsSep " " bootargs}
          booti 0xf0080000 0xf8000000:''${initramfs_size} 0xf3000000
        '';
      };
    in {
      "${scriptName}" = script;
    };

in
doKernel rec {
  inherit source config;
  passthru = {
    inherit mkDefaultPayload;
  };
}

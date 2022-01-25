{ lib, writeText, runCommand
, icecapSrc, icecapExternalSrc
, linuxHelpers
}:

with linuxHelpers.uBoot;

let

  source = icecapExternalSrc.u-boot.host.unified;

  preConfig = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = icecapSrc.relative "support/hypervisor/host/virt/u-boot.defconfig";
  };

  # config = preConfig;

  config = runCommand "config" {} ''
    substitute ${preConfig} $out \
      --replace 'BOOTCOMMAND="x"' 'BOOTCOMMAND="${bootcmd}"'
  '';

  scriptAddr = "0x80000000";
  scriptName = "load-host.script.uimg";
  scriptPath = "./payload/${scriptName}"; # HACK

  bootcmd = "smhload ${scriptPath} ${scriptAddr}; source ${scriptAddr}";

  mkDefaultPayload = { kernel, initramfs, dtb, bootargs }:
    let
      kernelAddr = "0x80080000";
      initramfsAddr = "0x88000000";
      dtbAddr = "0x83000000";
      script = linuxHelpers.uBoot.mkImage {
        type = "script";
        data = writeText "script.txt" ''
          smhload ${kernel} ${kernelAddr}
          smhload ${initramfs} ${initramfsAddr} initramfs_end
          setexpr initramfs_size ''${initramfs_end} - ${initramfsAddr}
          smhload ${dtb} ${dtbAddr}
          setenv bootargs ${lib.concatStringsSep " " bootargs}
          booti ${kernelAddr} ${initramfsAddr}:''${initramfs_size} ${dtbAddr}
        '';
      };
    in {
      "${scriptName}" = script;
    };

in
build rec {
  inherit source config;
  passthru = {
    inherit mkDefaultPayload;
  };
}

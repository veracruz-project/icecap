{ lib, cmakeUtils, seL4EcosystemRepos
, icecapConfig, selectIceCapPlat
}:

with cmakeUtils;

let

  kernelPlat = selectIceCapPlat {
    virt = "qemu-arm-virt";
    rpi4 = "bcm2711";
  };

  common = {
    KernelArch = STRING "arm";
    KernelSel4Arch = STRING "aarch64";
    KernelPlatform = STRING kernelPlat;
    KernelArmHypervisorSupport = ON;
    KernelVerificationBuild = OFF;
    KernelDebugBuild = ON;
    KernelOptimisation = STRING "-O3"; # TODO beware (default is -O2)
    KernelMaxNumNodes = selectIceCapPlat {
      virt = STRING "4";
      rpi4 = STRING "4";
    };
    KernelArmVtimerUpdateVOffset = OFF;
    KernelArmDisableWFIWFETraps = ON; # TODO
    KernelArmExportVCNTUser = ON; # HACK so VMM can get CNTV_FRQ
  } // lib.optionalAttrs icecapConfig.benchmark {
    KernelBenchmarks = STRING "track_utilisation";
  };

in {

  icecap = common // {
    KernelRootCNodeSizeBits = STRING "18"; # default: 12
    # KernelStackBits = STRING "15";
  };

}.${icecapConfig.profile}

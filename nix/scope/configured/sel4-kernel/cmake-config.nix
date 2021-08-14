{ configUtils, repos
, config, icecapPlat
}:

with configUtils;

let

  kernelPlat = {
    virt = "qemu-arm-virt";
    rpi4 = "bcm2711";
  }.${icecapPlat};

  common = {
    KernelArch = STRING "arm";
    KernelSel4Arch = STRING "aarch64";
    KernelPlatform = STRING kernelPlat;
    KernelArmHypervisorSupport = ON;
    KernelVerificationBuild = OFF;
    KernelDebugBuild = ON;
    KernelOptimisation = STRING "-Og";
    KernelMaxNumNodes = {
      virt = STRING "4";
      rpi4 = STRING "4"; # TODO
    }.${icecapPlat};
    KernelArmVtimerUpdateVOffset = OFF;
    KernelArmDisableWFIWFETraps = ON; # TODO
    KernelArmExportVCNTUser = ON; # HACK so VMM can get CNTV_FRQ
  };

in {

  icecap = common // {
    KernelRootCNodeSizeBits = STRING "18"; # default: 12
    # KernelStackBits = STRING "15";
    # KernelPrinting = ON;
    # KernelUserStackTraceLength = 32;
  };

  sel4test = common // {
    KernelDomainSchedule = STRING (repos.rel.sel4test "domain_schedule.c");

    # TODO
    Sel4testHaveCache = {
      virt = OFF;
      rpi4 = ON;
    }.${icecapPlat};
    LibUtilsDefaultZfLogLevel = STRING "3"; # 0-5, 0 is most verbose
  };

}.${config.profile}

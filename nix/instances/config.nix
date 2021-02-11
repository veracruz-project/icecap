{ configUtils, icecapPlat, repos }:

with configUtils;

let
  kernelPlat = {
    virt = "virt-aarch64";
    rpi4 = "bcm2711";
  }.${icecapPlat};
in

rec {

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

  sel4test = common // {
    KernelDomainSchedule = STRING (repos.rel.sel4test "domain_schedule.c");
    Sel4testHaveCache = {
      virt = OFF;
      rpi4 = ON;
    }.${icecapPlat};
    LibUtilsDefaultZfLogLevel = STRING "3"; # 0-5, 0 is most verbose
  };

  icecap = common // {
    KernelRootCNodeSizeBits = STRING "18"; # default: 12
    # KernelStackBits = STRING "15";
    # KernelPrinting = ON;
    # KernelUserStackTraceLength = 32;
  };

}

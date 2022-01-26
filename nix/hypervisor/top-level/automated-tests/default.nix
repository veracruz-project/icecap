{ lib, pkgs, framework, instances }:

rec {
  cases = {
    hypervisor = framework.automatedTests.automateQemuBasic {
      script = "${instances.tests.hypervisor.virt.run}/run";
      timeout = if pkgs.dev.hostPlatform.isAarch64 then 600 else 300;
    };
  };

  runAll = framework.automatedTests.mkRunAll cases;
}

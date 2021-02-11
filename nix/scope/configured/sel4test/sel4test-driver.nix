{ runCMake, stdenvRoot, repos, remoteLibs
, mkCpioObj, mkCpio
, sel4test-tests
}:

let
  driver = mkCpioObj {
    archive-cpio = mkCpio [
      { path = "sel4test-tests"; contents = "${sel4test-tests}/bin/sel4test-tests"; }
    ];
    symbolName = "_cpio_archive";
    libName = "driver";
  };

in
runCMake stdenvRoot rec {
  baseName = "sel4test-driver";
  source = repos.rel.sel4test "apps/${baseName}";
  extraPropagatedBuildInputs = with remoteLibs; [
    driver
    libsel4allocman
    libsel4utils
    libsel4test
    libsel4muslcsys
    libsel4testsupport
  ];
  configPrefixes = [
    "Sel4test"
  ];
}

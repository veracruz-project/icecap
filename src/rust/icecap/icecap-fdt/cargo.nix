{ mk, localCrates, hostPlatform }:

mk {
  name = "icecap-fdt";
  localDependencies = with localCrates; if hostPlatform.system == "aarch64-none" then [
    icecap-failure
  ] else [
    icecap-failure_dummy
  ];
  dependencies = {
    log = "*";
  };
}

{ mk, localCrates, serdeMin, hostPlatform }:

mk {
  name = "icecap-base-config";
  localDependencies = with localCrates; if hostPlatform.system == "aarch64-none" then [
    icecap-sel4
    icecap-runtime
  ] else [
    icecap-sel4_dummy
    icecap-runtime_dummy
  ];
  dependencies = {
    serde = serdeMin;
  };
}

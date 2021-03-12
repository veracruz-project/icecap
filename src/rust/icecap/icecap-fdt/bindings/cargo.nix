{ mk, localCrates, hostPlatform, serdeMin }:

mk {
  name = "icecap-fdt-bindings";
  localDependencies = with localCrates; [
    icecap-fdt
  ] ++ (if hostPlatform.system == "aarch64-none" then [
    icecap-failure
  ] else [
    icecap-failure_dummy
  ]);
  dependencies = {
    log = "*";
    serde = serdeMin;
  };
}

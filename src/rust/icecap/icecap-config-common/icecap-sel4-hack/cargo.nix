{ mk, localCrates, hostPlatform }:

mk {
  name = "icecap-sel4-hack";
  localDependencies = with localCrates; if hostPlatform.system == "aarch64-none" then [
    icecap-sel4
    icecap-runtime
  ] else [
    icecap-sel4-hack-meta
  ];
}

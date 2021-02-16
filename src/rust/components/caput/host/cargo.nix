{ mk, localCrates }:

mk {
  name = "icecap-caput-host";
  localDependencies = with localCrates; [
    icecap-caput-types
  ];
}

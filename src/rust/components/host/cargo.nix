{ mk, localCrates }:

mk {
  name = "icecap-host-core";
  localDependencies = with localCrates; [
    icecap-caput-types
  ];
  dependencies = {
    libc = "*";
  };
}

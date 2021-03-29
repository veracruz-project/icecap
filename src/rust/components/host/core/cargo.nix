{ mk, localCrates }:

mk {
  name = "icecap-host-core";
  localDependencies = with localCrates; [
    icecap-resource-server-types
    icecap-rpc
  ];
  dependencies = {
    libc = "*";
  };
}

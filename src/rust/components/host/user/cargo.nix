{ mk, localCrates }:

mk {
  name = "icecap-host-user";
  localDependencies = with localCrates; [
    icecap-resource-server-types
    icecap-rpc
  ];
  dependencies = {
    libc = "*";
    cfg-if = "*";
  };
}

{ mk, localCrates }:

mk {
  name = "icecap-host-user";
  localDependencies = with localCrates; [
    icecap-host-vmm-types
    icecap-resource-server-types
    icecap-rpc
  ];
  dependencies = {
    libc = "*";
    cfg-if = "*";
  };
}

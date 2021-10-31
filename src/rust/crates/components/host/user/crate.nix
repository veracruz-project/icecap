{ mk, localCrates }:

mk {
  nix.name = "icecap-host-user";
  nix.local.dependencies = with localCrates; [
    icecap-host-vmm-types
    icecap-resource-server-types
    icecap-rpc
  ];
  dependencies = {
    libc = "*";
    cfg-if = "*";
  };
}
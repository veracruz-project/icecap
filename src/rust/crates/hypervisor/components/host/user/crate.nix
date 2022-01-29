{ mk, localCrates, postcardCommon }:

mk {
  nix.name = "icecap-host-user";
  nix.local.dependencies = with localCrates; [
    dyndl-types
    icecap-host-vmm-types
    icecap-resource-server-types
    icecap-rpc-types
  ];
  dependencies = {
    libc = "*";
    cfg-if = "*";
    postcard = postcardCommon;
  };
  nix.passthru.noDoc = true;
}

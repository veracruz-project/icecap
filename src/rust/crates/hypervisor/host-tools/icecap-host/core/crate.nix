{ mkLinux, localCrates, postcardCommon }:

mkLinux {
  nix.name = "icecap-host-core";
  nix.local.dependencies = with localCrates; [
    dyndl-types
    hypervisor-host-vmm-types
    hypervisor-resource-server-types
    icecap-rpc-types
  ];
  dependencies = {
    libc = "*";
    cfg-if = "*";
    postcard = postcardCommon;
  };
  nix.passthru.excludeFromDocs = true;
}

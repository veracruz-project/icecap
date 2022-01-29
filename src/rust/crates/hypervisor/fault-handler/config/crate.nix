{ mk, localCrates, serdeMin }:

mk {
  nix.name = "hypervisor-fault-handler-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}

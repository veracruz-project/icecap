{ mkLinuxBin, localCrates }:

mkLinuxBin {
  nix.name = "hypervisor-serialize-event-server-out-index";
  nix.local.dependencies = with localCrates; [
    hypervisor-event-server-types
    finite-set
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
  };
  nix.passthru.excludeFromDocs = true;
}

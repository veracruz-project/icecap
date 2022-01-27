{ mkBin, localCrates }:

mkBin {
  nix.name = "icecap-serialize-event-server-out-index";
  nix.local.dependencies = with localCrates; [
    icecap-event-server-types
    finite-set
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
  };
  nix.hack.noDoc = true;
}

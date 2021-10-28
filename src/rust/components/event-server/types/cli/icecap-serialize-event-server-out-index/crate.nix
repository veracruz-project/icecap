{ mkBin, localCrates }:

mkBin {
  nix.name = "icecap-serialize-event-server-out-index";
  nix.localDependencies = with localCrates; [
    icecap-event-server-types
    finite-set
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
  };
}

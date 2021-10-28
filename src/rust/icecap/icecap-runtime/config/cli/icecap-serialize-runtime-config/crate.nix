{ mkBin, localCrates }:

mkBin {
  nix.name = "icecap-serialize-runtime-config";
  nix.localDependencies = with localCrates; [
    icecap-runtime-config
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
  };
}

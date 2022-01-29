{ mkLinuxBin, localCrates }:

mkLinuxBin {
  nix.name = "icecap-serialize-runtime-config";
  nix.local.dependencies = with localCrates; [
    icecap-runtime-config
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
  };
}

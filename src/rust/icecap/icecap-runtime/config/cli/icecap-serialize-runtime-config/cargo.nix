{ mkBin, localCrates }:

mkBin {
  name = "icecap-serialize-runtime-config";
  localDependencies = with localCrates; [
    icecap-runtime-config
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
  };
}

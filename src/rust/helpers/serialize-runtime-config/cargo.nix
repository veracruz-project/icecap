{ mkBin, localCrates }:

mkBin {
  name = "serialize-runtime-config";
  localDependencies = with localCrates; [
    icecap-runtime-config
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
  };
}

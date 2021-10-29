{ mk, localCrates }:

mk {
  nix.name = "icecap-ring-buffer";
  nix.local.dependencies = with localCrates; [
    icecap-sel4
    icecap-config
  ];
  dependencies = {
    log = "*";
    tock-registers = "*";
  };
}

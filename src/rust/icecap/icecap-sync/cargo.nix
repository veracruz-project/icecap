{ mk, localCrates }:

mk {
  name = "icecap-sync";
  localDependencies = with localCrates; [
    icecap-sel4
  ];
}

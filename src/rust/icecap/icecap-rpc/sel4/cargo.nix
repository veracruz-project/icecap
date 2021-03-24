{ mk, localCrates }:

mk {
  name = "icecap-rpc-sel4";
  localDependencies = with localCrates; [
    icecap-sel4
    icecap-rpc
  ];
}

{ mk, localCrates }:

mk {
  name = "icecap-p9";
  localDependencies = with localCrates; [
    icecap-p9-wire-format-derive
  ];
  dependencies = {
    libc = "*";
  };
  features.trace = [];
}

{ mk }:

mk {
  name = "icecap-sel4-sys";
  buildScript = { icecap-sel4-sys-gen }: {
    rustc-env.GEN_RS = icecap-sel4-sys-gen;
    rustc-link-lib = [
      "outline" "sel4"
      "icecap_runtime" "icecap_utils" "icecap_pure" # TODO this should be elsewhere
    ];
  };
}

{ mkBin, localCrates, serdeMin }:

mkBin {
  name = "mirage";
  localDependencies = with localCrates; [
    icecap-linux-syscall
    icecap-std
    icecap-start-generic
  ];
  dependencies = {
    serde = serdeMin;
    serde_json = { version = "*"; default-features = false; features = [ "alloc" ]; };
  };
  buildScript = { stdenv }: {
    # doesn't work because of circular dependencies. rustc deduplicates these
    # rustc-link-lib = [
    #   "icecap_mirage_glue" "mirage" "sel4asmrun" "c" "gcc"
    # ];
    rustc-link-search = [
      (let cc = stdenv.cc.cc; in "${cc}/lib/gcc/${cc.targetConfig}/${cc.version}") # TODO shouldn't be necessary
    ];
  };
}

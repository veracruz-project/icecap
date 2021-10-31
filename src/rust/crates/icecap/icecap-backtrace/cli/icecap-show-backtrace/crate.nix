{ mkBin, localCrates }:

mkBin {
  nix.name = "icecap-show-backtrace";
  nix.local.dependencies = with localCrates; [
    icecap-backtrace-types
  ];
  dependencies = {
    addr2line = "0.11.0";
    backtrace = "*";
    clap = "*";
    cpp_demangle = "*";
    fallible-iterator = "*";
    gimli = "0.20.0";
    hex = "*";
    log = "*";
    memmap = "*";
    object = "0.17.*";
    pinecone = "*";
    rustc-demangle = "*";
    serde = "*";
  };
}

{ mkBin, localCrates }:

mkBin {
  name = "caput";
  localDependencies = with localCrates; [
    icecap-std
    icecap-caput-types
    icecap-qemu-ring-buffer-server-config
    dyndl-types
    dyndl-realize
  ];
  dependencies = {
    pinecone = "*";
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
    serde_json = { version = "*"; default-features = false; features = [ "alloc" ]; };
  };
}

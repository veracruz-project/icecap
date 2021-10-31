{ mk, serdeMin }:

mk {
  nix.name = "icecap-backtrace-types";
  dependencies = {
    hex = { version = "*"; default-features = false; features = [ "alloc" ]; };
    pinecone = "*";
    serde = serdeMin;
  };
}

{ mk, serdeMin }:

mk {
  name = "icecap-backtrace-types";
  dependencies = {
    hex = { version = "*"; default-features = false; features = [ "alloc" ]; };
    pinecone = "*";
    serde = serdeMin;
  };
}

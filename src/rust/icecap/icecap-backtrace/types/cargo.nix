{ mk, serdeMin }:

mk {
  name = "icecap-backtrace-types";
  dependencies = {
    hex = { version = "*"; default-features = false; };
    pinecone = "*";
    serde = serdeMin;
  };
}

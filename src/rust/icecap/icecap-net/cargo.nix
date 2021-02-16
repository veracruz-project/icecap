{ mk, localCrates }:

mk {
  name = "icecap-net";
  localDependencies = with localCrates; [
    icecap-interfaces
  ];
  dependencies = {
    managed = { version = "*"; default-features = false; features = [ "map" ]; };
    smoltcp = {
      version = "0.6.0";
      default-features = false;
      features = [
        "alloc"
        "log"
        "verbose"
        "ethernet"
        "proto-ipv4"
        "proto-igmp"
        "proto-ipv6"
        "socket-raw"
        "socket-icmp"
        "socket-udp"
        "socket-tcp"
      ];
    };
  };
}

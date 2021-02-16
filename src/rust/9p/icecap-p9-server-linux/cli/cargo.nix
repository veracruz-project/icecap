{ mkBin, localCrates }:

mkBin {
  name = "icecap-p9-server-linux-cli";
  localDependencies = with localCrates; [
    icecap-p9-server-linux
  ];
  dependencies = {
    getopts = "*";
    libc = "*";
    log = "*";
    env_logger = "*";
  };
}

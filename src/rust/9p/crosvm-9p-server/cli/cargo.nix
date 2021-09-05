{ mkBin, localCrates }:

mkBin {
  name = "crosvm-9p-server-cli";
  localDependencies = with localCrates; [
    crosvm-9p-server
  ];
  dependencies = {
    getopts = "*";
    libc = "*";
    log = "*";
    env_logger = "*";
  };
}
